#!/bin/sh

set -eux

err()
{
	echo "${0##*/}: ERROR: $@."
	exit 1
}

case "$(uname)" in
Darwin)
	so_ext=dylib
	;;
FreeBSD|Linux)
	so_ext=so
	;;
*)
	err "Unknown/unsupported OS"
	;;
esac

: ${OPENSSL_ROOT=/nonexistent}
if [ ! -d "$OPENSSL_ROOT" ]; then
	for _pkgconfig in pkgconf pkg-config; do
		if pkgconfig=$(which $_pkgconfig 2>/dev/null); then
			break
		fi
	done
	[ -n "$pkgconfig" ] || err "Could not find pkg-config compatible tool."

	OPENSSL_ROOT=$("$pkgconfig" --variable=prefix openssl)
fi
if [ -d "$OPENSSL_ROOT" ]; then
	OPENSSL_MODULE_DIR="$OPENSSL_ROOT/lib/ossl-modules"
	FIPS_PROVIDER_SO="$OPENSSL_MODULE_DIR/fips.$so_ext"
fi
if [ ! -r "${FIPS_PROVIDER_SO:-/nonexistent}" ]; then
	err "Could not find a copy of OpenSSL with the FIPS provider; please specify OPENSSL_ROOT to a copy of OpenSSL which contains the FIPS provider."
fi

rm -f CMakeCache.txt
cmake --fresh -DCMAKE_BUILD_TYPE=Debug -DOpenSSL_ROOT="$OPENSSL_ROOT" .
make clean
make all

tmpconf="$(mktemp ossl_cnf_XXXXXX)"
fipsconf="$tmpconf.fips"
#trap "rm -f $tmpconf $fipsconf" EXIT INT TERM

cat > $tmpconf <<EOF
config_diagnostics = 1
openssl_conf = openssl_init

.include \${ENV::PWD}/$fipsconf

[openssl_init]
providers = provider_sect

# Load base + fips (default doesn't jive with fips).
[provider_sect]
base = base_sect
fips = fips_sect

[base_sect]
activate = 1
EOF

export PATH="$OPENSSL_ROOT/bin:$PATH"
FIPS_SO="$OPENSSL_MODULE_DIR/fips.$so_ext"
openssl fipsinstall -quiet -provider_name fips -module $FIPS_SO -out $fipsconf

export OPENSSL_CONF="$tmpconf"

openssl fipsinstall -config $tmpconf -in $fipsconf

set +e

echo "Listing all providers"
env OPENSSL_CONF="$tmpconf" openssl list -providers
for provider in base fips; do
	printf "$provider provider info follows:\n"
	openssl list -provider $provider
done

export LD_LIBRARY_PATH="$PWD:$PWD/lib"
export PATH="$PWD:$PWD/bin:$PATH"

which demo_exe || exit

#for f in $tmpconf $fipsconf; do echo "$f.."; cat $f; done; exit 0

for flag_combo in "" "-L" "-LN" "-N"; do
	printf "Flag combo: %s\n" "$flag_combo"
	demo_exe $flag_combo
done

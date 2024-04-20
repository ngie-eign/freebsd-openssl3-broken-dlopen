#!/bin/sh

set -eu
#set -x

_msg()
{
	local level=$1; shift

	echo "$(basename "$0"): $level: $@."
}

err()
{
	_msg "ERROR" "$@"
	exit 1
}

info()
{
	_msg "INFO" "$@"
}

timeout=timeout
case "$(uname)" in
Darwin)
	so_ext=dylib
	timeout=gtimeout
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
	LEGACY_PROVIDER_SO="$OPENSSL_MODULE_DIR/legacy.$so_ext"
fi
if [ ! -r "${FIPS_PROVIDER_SO:-/nonexistent}" -o \
     ! -r "${LEGACY_PROVIDER_SO:-/nonexistent}" ]; then
	err "Could not find a copy of OpenSSL with the FIPS/legacy providers" \
	    "please specify OPENSSL_ROOT to a copy of OpenSSL which contains the" \
	    "beforementioned providers."
fi

rm -f CMakeCache.txt
cmake --fresh -DCMAKE_BUILD_TYPE=Debug -DOpenSSL_ROOT="$OPENSSL_ROOT" .
make -s clean
make -s all

tmpconf="$(mktemp ossl_cnf_XXXXXX)"
fipsconf="$tmpconf.fips"
trap "rm -f $tmpconf $fipsconf" EXIT INT TERM

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

export LD_LIBRARY_PATH="$OPENSSL_ROOT/lib:${LD_LIBRARY_PATH:-}"
export PATH="$OPENSSL_ROOT/bin:$PATH"
FIPS_SO="$OPENSSL_MODULE_DIR/fips.$so_ext"
openssl fipsinstall -quiet -provider_name fips -module $FIPS_SO -out $fipsconf

export OPENSSL_CONF="$tmpconf"

info "Verifying FIPS provider is usable."
openssl fipsinstall -config $tmpconf -in $fipsconf

set +e

echo "Listing all providers"
env OPENSSL_CONF="$tmpconf" openssl list -providers

export LD_LIBRARY_PATH="$PWD:$PWD/lib"
export PATH="$PWD:$PWD/bin:$PATH"

demo_exe=$(which demo_exe) || exit

#for f in $tmpconf $fipsconf; do echo "$f.."; cat $f; done; exit 0

for flag_combo in "" "-L" "-LN" "-N"; do
	flag_msg=$(printf "Flags: '%s'\n" "$flag_combo")
	info "$flag_msg"
	$timeout -s ABRT 10 $demo_exe $flag_combo
done

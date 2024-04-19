# freebsd-openssl3-broken-dlopen
Simple reproducer to show that dlopen(..., RTLD_LOCAL) doesn't play nicely with OpenSSL 3.0

# Requirements

- OpenSSL 3.0+ built with the FIPS provider.
- bmake OR cmake.
- Bourne shell compatible OS.
- timeout program or coreutils (available with Homebrew on MacOS)

# Building/running the reproducer

```
./run_tests.sh
```

# Building with cmake

## cmake on MacOS

This is applicable to other OSes to some degree...

https://www.scivision.dev/cmake-macos-find-openssl/

Pass any relevant variables via the `$CMAKE_ARGS` environment variable.

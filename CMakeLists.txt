# 3.19 adds needed for adequate FindOpenSSL macro support.
cmake_minimum_required(VERSION 3.19)
project(freebsd-openssl3-broken-dlopen)

find_package(OpenSSL 3.0.0 REQUIRED)

if (CMAKE_SYSTEM_NAME EQUAL "FreeBSD")
	# XXX: there's probably a better way for checking for lld support.
	set(CMAKE_EXE_LINKER_FLAGS "-Wl,-export-dynamic -Llib")
endif()

add_executable(demo_exe bin/exe.c)
add_library(demo_lib SHARED lib/lib.c)

target_compile_options(demo_exe PRIVATE
	-Wall -Wextra -Wpedantic
)
target_compile_options(demo_lib PRIVATE
	-Wall -Wextra -Wpedantic
)

target_link_libraries(demo_lib OpenSSL::Crypto)

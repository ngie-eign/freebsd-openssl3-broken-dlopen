#include <openssl/conf.h>
#include <openssl/err.h>
#include <openssl/provider.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "lib.h"

void
load_fips(void)
{
	OSSL_PROVIDER *fips;
	char *openssl_conf;
	int conf_modules_load_flags;

	conf_modules_load_flags = CONF_MFLAGS_DEFAULT_SECTION;

	openssl_conf = getenv("OPENSSL_CONF");
	if (openssl_conf != NULL) {
		openssl_conf = strdup(openssl_conf);
	}

	fprintf(stderr, "OPENSSL_CONF: %s\n", openssl_conf);

	fprintf(stderr, "loading config\n");
	fflush(stderr);

	if (CONF_modules_load_file(openssl_conf, NULL, conf_modules_load_flags)
	    != 1) {
		ERR_print_errors_fp(stderr);
		abort();
	}
	fprintf(stderr, "loaded config\n");
	fflush(stderr);

	fips = OSSL_PROVIDER_load(NULL, "fips");
	if (fips == NULL) {
		ERR_print_errors_fp(stderr);
		abort();
	}

	fprintf(stderr, "fips provider loaded\n");
	fflush(stderr);

	free(openssl_conf);
}

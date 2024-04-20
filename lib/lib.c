#include <openssl/conf.h>
#include <openssl/err.h>
#include <openssl/provider.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "lib.h"

static void
_test_provider_load(const char* provider_name)
{
	OSSL_PROVIDER *prov;

	prov = OSSL_PROVIDER_load(NULL, provider_name);
	if (prov == NULL) {
		ERR_print_errors_fp(stderr);
		abort();
	}

	fprintf(stderr, "%s provider loaded\n", provider_name);

	if (OSSL_PROVIDER_available(NULL, provider_name) == 1) {
		fprintf(stderr, "%s provider 'available'.\n",
		    provider_name);
	} else {
		fprintf(stderr,
		    "%s provider not 'available'; see errors below for more details.\n",
		    provider_name);
		ERR_print_errors_fp(stderr);
	}
	fflush(stderr);

	if (OSSL_PROVIDER_unload(prov) != 1) {
		ERR_print_errors_fp(stderr);
		abort();
	}
	fprintf(stderr, "%s provider unloaded successfully\n", provider_name);
}

static void
load_fips(void)
{
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

	_test_provider_load("fips");

	free(openssl_conf);
}

static void
load_legacy(void)
{

	_test_provider_load("legacy");
}

void
load_providers(void)
{
	load_fips();
	load_legacy();
}

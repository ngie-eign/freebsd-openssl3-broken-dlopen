#include <dlfcn.h>
#include <err.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

typedef	void (*load_provider_t)(void);

#ifdef	__APPLE__
#define	SO_EXT	"dylib"
#else
#define	SO_EXT	"so"
#endif

int
main(int argc, char **argv)
{
	void *dlhandle;
	int dlopen_flags = 0;
	int optch;
	bool dlopen_local = false;
	bool dlopen_now = false;

	while ((optch = getopt(argc, argv, "LN")) != -1)
		switch (optch) {
		case 'L':
			dlopen_local = true;
			break;
		case 'N':
			dlopen_now = true;
			break;
		default:
			fprintf(stderr, "usage: demo_exe [-LN]");
			exit(1);
		}

	printf("RTLD_NOW: %s\n", dlopen_now ? "yes" : "no");
	printf("RTLD_LOCAL: %s\n", dlopen_local ? "yes" : "no");

	dlopen_flags |= dlopen_now ? RTLD_NOW : RTLD_LAZY;
	dlopen_flags |= dlopen_local ? RTLD_LOCAL : RTLD_GLOBAL;

	/* printf("dlopen_flags are: %d\n", dlopen_flags); */

	/* Oh cmake... you tricky beast with your library naming.. */
	printf("Calling dlopen..\n");
	dlhandle = dlopen("libdemo_lib." SO_EXT, dlopen_flags);
	if (dlhandle == NULL) {
		warnx("ytho?");
		errx(1, "dlopen failed: %s", dlerror());
	}

	printf("Calling dlfunc..\n");
	load_provider_t load_providers = (load_provider_t)dlsym(dlhandle, "load_providers");
	if (load_providers == NULL) {
		warnx("huh?");
		errx(1, "dlfunc failed: %s", dlerror());
	}

	load_providers();

	dlclose(dlhandle);

	return (0);
}

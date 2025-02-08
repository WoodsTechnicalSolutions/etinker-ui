/*
 * main C++ application entry point
 *
 */

#include <cstdio>
#include <cstdbool>

#include "etinker-ui.h"

int main(int argc, char **argv, char **envp)
{
	int rc;
	bool debug = false;
	etinker_ui *ui;

	if ((argc > 0) && argv[1]) {
		if (!strncmp(argv[1], "debug", 5))
			debug = true;
	}

	if (debug)
		fprintf(stdout, "etinker-ui: starting\n");

	ui = new etinker_ui(debug);

	rc = Fl::run();

	if (debug)
		fprintf(stdout, "etinker-ui: exiting (%d)\n", rc);

	return rc;
}

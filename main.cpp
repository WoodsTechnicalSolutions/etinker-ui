/*
 * main C++ application entry point
 *
 */

#include <cstdio>

#include <FL/Fl.H>

#include "etinker-ui.h"

int main(int argc, char **argv, char **envp)
{
	int rc;
	etinker_ui window;

	fprintf(stdout, "etinker-ui: starting\n");

	rc = Fl::run();

	fprintf(stdout, "etinker-ui: ending (%d)\n", rc);

	return rc;
}

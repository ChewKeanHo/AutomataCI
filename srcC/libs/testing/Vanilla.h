/*
 * [ LICENSE CLAUSE HERE ]
 */
#ifndef TESTING_H
#define TESTING_H




#pragma GCC diagnostic ignored "-Wunknown-pragmas"
#pragma clang diagnostic ignored "-Wunknown-pragmas"
#pragma GCC diagnostic ignored "-Wvariadic-macros"
#pragma clang diagnostic ignored "-Wgnu-zero-variadic-macro-arguments"

#include <stdio.h>

struct Scenario {
	long ID;
	const char *Name;
	const char *Description;
};

#define Logf(...) fprintf(stderr,##__VA_ARGS__);




#endif

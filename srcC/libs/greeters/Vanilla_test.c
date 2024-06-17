/*
 * [ LICENSE CLAUSE HERE ]
 */
#include <string.h>

#include "../testing/Vanilla.h"
#include "./Vanilla.c"




/* define test algorithm */
static int test_process_api(struct Scenario *s, const char *name, const char *location) {
	/* prepare */
	char str[500] = { '\0' };


	/* test */
	Process(str, name, location);


	/* log output */
	Logf("TEST CASE\n");
	Logf("=========\n");

	Logf("Test Scenario ID\n");
	Logf("	%ld\n", s->ID);

	Logf("Test Scenario Name\n");
	Logf("	%s\n", s->Name);

	Logf("Test Scenario Description\n");
	Logf("	%s\n", s->Description);

	Logf("Input Name\n");
	Logf("	%s\n", name);

	Logf("Input Location\n");
	Logf("	%s\n", location);

	Logf("Got Output:\n");
	Logf("	%s\n", str);

	Logf("\n");


	/* assert */
	Logf("Asserting conditions...\n");
	if (strcmp(str, "") != 0) {
		if (strcmp(name, "") == 0 && strcmp(location, "") == 0) {
			Logf("[ FAILED ] Expecting string but got empty instead.\n\n\n");
			return 1;
		}
	} else {
		/* it's an empty output */
		if (!(strcmp(name, "") == 0 && strcmp(location, "") == 0)) {
			Logf("[ FAILED ] Expecting empty string but got result instead.\n\n\n");
			return 1;
		}
	}


	/* report status */
	Logf("[ PASSED ]\n\n\n");
	return 0;
}




/* execute test suite on run */
int main(void) {
	int exit=0;
	struct Scenario s;


	/* setup test suite */
	s.ID = 0;
	s.Name = "Test Process(...) API";


	/* run test */
	s.Description = "Test Process() is able to work with proper name and location.";
	if (test_process_api(&s, "Alpha", "Rivendell") != 0) {
		exit=1;
	}
	s.ID++;

	s.Description = "Test Process() is able to work with proper name and empty location.";
	if (test_process_api(&s, "Alpha", "") != 0) {
		exit=1;
	}
	s.ID++;

	s.Description = "Test Process() is able to work with empty name and proper location.";
	if (test_process_api(&s, "", "Rivendell") != 0) {
		exit=1;
	}
	s.ID++;

	s.Description = "Test Process() is able to work with empty name and empty location.";
	if (test_process_api(&s, "", "") != 0) {
		exit=1;
	}
	s.ID++;


	/* report status */
	return exit;
}

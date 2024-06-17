/*
 * [ LICENSE CLAUSE HERE ]
 */
#include <stdio.h>

#include "libs/entities/Vanilla.h"
#include "libs/locations/Vanilla.h"
#include "libs/greeters/Vanilla.h"




int main(int argc, char *argv[]) {
	int i;


	/* run functions */
	char str[500] = { '\0' };
	Process(str, NAME, LOCATION);
	printf("Hello %s\n", str);


	/* handle parameters */
	printf("\n\nThese are your given arguments: \n");
	for (i=0; i<argc; i++) {
		printf("argv[%d] = %s\n", i, argv[i]);
	}


	/* report status */
	return 0;
}

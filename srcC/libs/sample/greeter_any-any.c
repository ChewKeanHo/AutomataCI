/*
 * [ COPYRIGHT CLAUSE HERE ]
 */
static int len(const char *str) {
	const char *anchor = str;
	while (*str) {
		str++;
	}
	return str - anchor;
}




extern void Process(char writer[500], const char *name, const char *location) {
	int i=0, j;

	if (!name || len(name) == 0 || name[0] == '\0' ) {
		if (!location || len(location) == 0 || location[0] == '\0' ) {
			writer[i] = '\0';
			return;
		}

		/* valid location only */
		writer[i] = 's';
		i++;
		writer[i] = 't';
		i++;
		writer[i] = 'r';
		i++;
		writer[i] = 'a';
		i++;
		writer[i] = 'n';
		i++;
		writer[i] = 'g';
		i++;
		writer[i] = 'e';
		i++;
		writer[i] = 'r';
		i++;
		writer[i] = ' ';
		i++;
		writer[i] = 'f';
		i++;
		writer[i] = 'r';
		i++;
		writer[i] = 'o';
		i++;
		writer[i] = 'm';
		i++;
		writer[i] = ' ';
		i++;

		j=0;
		while (location[j] != '\0') {
			writer[i] = location[j];
			i++;
			j++;
		}

		writer[i] = '!';
		i++;
		writer[i] = '\0';
		return;
	} else if (!location || len(location) == 0 || location[0] == '\0' ) {
		/* valid name only */
		j=0;
		while (name[j] != '\0') {
			writer[i] = name[j];
			i++;
			j++;
		}

		writer[i] = '!';
		i++;
		writer[i] = '\0';
		return;
	} else {
		/* valid name and location */
		j=0;
		while (name[j] != '\0') {
			writer[i] = name[j];
			i++;
			j++;
		}

		writer[i] = ' ';
		i++;
		writer[i] = 'f';
		i++;
		writer[i] = 'r';
		i++;
		writer[i] = 'o';
		i++;
		writer[i] = 'm';
		i++;
		writer[i] = ' ';
		i++;

		j=0;
		while (location[j] != '\0') {
			writer[i] = location[j];
			i++;
			j++;
		}

		writer[i] = '!';
		i++;
		writer[i] = '\0';
		return;
	}
}

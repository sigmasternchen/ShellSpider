#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {

	if (strlen(getenv("QUERY_STRING")) == 0) {
		printf("Status: 302 Found\n");
		printf("Location: ?foo=bar\n\n");
	} else {
		printf("Content-Type: text/plain\n\n");

		printf("This Server is running %s.\n", getenv("SERVER_SOFTWARE"));
		printf("The query string is %s.\n", getenv("QUERY_STRING"));
	}
	
	return 0;
}

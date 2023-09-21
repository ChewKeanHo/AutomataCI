// [ COPYRIGHT CLASE HERE]

// AutomataCI is a sample program demonstrating a simple Go application.
package main

import (
	"fmt"
	"os"

	"local/libs/entity"
	"local/libs/greeter"
	"local/libs/location"
)

// Main is the starting function of the Go application
func main() {
	fmt.Fprintf(os.Stderr,
		"Hello %s\n",
		greeter.Process(entity.NAME, location.NAME))
}

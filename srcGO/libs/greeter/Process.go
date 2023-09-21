// [ COPYRIGHT CLASE HERE]

package greeter

// Process is to generate a printable statement for a name and a location.
func Process(name string, location string) string {
	switch {
	case name == "" && location == "":
		return ""
	case name == "":
		return "stranger from " + location + "!"
	case location == "":
		return name + "!"
	default:
		return name + " from " + location + "!"
	}
}

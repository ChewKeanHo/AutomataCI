// [ COPYRIGHT CLASE HERE]




export function Process(name: string, location: string): string {
	if (name == "" && location == "") {
		return ""
	} else if (name == "") {
		return "stranger from " + location + "!"
	} else if (location == "") {
		return name + "!"
	} else {
		return name + " from " + location + "!"
	}
}

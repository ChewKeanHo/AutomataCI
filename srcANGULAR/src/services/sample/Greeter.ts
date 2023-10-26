// [ COPYRIGHT CLASE HERE ]
import { Injectable } from '@angular/core';




@Injectable({
	providedIn: 'root'
})
export class Greeter {
	public Process(name: string, location: string): string {
		switch (true) {
		case name === "" && location === "":
			return "";
		case name === "":
			return "stranger from " + location + "!";
		case location === "":
			return name + "!";
		default:
			return name + " from " + location + "!";
		}
	}
}

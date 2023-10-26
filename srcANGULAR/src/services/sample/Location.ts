// [ COPYRIGHT CLASE HERE ]
import { Injectable } from '@angular/core';




@Injectable({
	providedIn: 'root'
})
export class Location {
	readonly Name: string;

	constructor() {
		this.Name = "Sample";
	}
}

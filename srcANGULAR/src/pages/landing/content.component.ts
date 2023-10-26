import { Component } from '@angular/core';

import { Greeter } from 'src/services/sample/Greeter';
import { Entity } from 'src/services/sample/Entity';
import { Location } from 'src/services/sample/Location';




@Component({
	selector: 'app-root',
	templateUrl: './content.component.html',
	styleUrls: ['./content.component.css']
})
export class LandingPageComponent {
	statement: string = '';


	constructor() {
		let greeter = new Greeter();
		let location = new Location();
		let entity = new Entity();

		this.statement = greeter.Process(entity.Name, location.Name);
	}
}

import { TestBed } from '@angular/core/testing';

import { Greeter } from 'src/services/sample/Greeter';




describe('Greeter', () => {
	beforeEach(() => TestBed.configureTestingModule({
	}));

	it('is able to work with proper name and proper location.', () => {
		let greeter = new Greeter();
		let output = greeter.Process('Alpha', 'Rivendell');
		expect(output != "").toEqual(true);
	});

	it('is able to work with proper name and empty location.', () => {
		let greeter = new Greeter();
		let output = greeter.Process('Alpha', '');
		expect(output != "").toEqual(true);
	});

	it('is able to work with empty name and proper location.', () => {
		let greeter = new Greeter();
		let output = greeter.Process('', 'Rivendell');
		expect(output != "").toEqual(true);
	});

	it('is able to work with empty name and empty location.', () => {
		let greeter = new Greeter();
		let output = greeter.Process('', '');
		expect(output == "").toEqual(true);
	});
});

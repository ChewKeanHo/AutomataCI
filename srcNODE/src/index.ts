// [ COPYRIGHT CLASE HERE]
import * as Entities from "./entities.js";
import * as Locations from "./locations.js";
import * as Greeters from "./greeters.js";




export function Main() {
	return Greeters.Process(Entities.NAME, Locations.NAME);
}

import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';

import { AppModule } from './module';




platformBrowserDynamic().bootstrapModule(AppModule)
	.catch(err => console.error(err));

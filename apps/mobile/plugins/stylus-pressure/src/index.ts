import { registerPlugin } from '@capacitor/core';

import type { StylusPressurePlugin } from './definitions';

const StylusPressure = registerPlugin<StylusPressurePlugin>('StylusPressure', {
  web: () => import('./web').then(m => new m.StylusPressureWeb()),
});

export * from './definitions';
export { StylusPressure };

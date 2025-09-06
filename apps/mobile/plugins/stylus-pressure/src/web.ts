import { WebPlugin } from '@capacitor/core';

import type { StylusPressurePlugin } from './definitions';

export class StylusPressureWeb extends WebPlugin implements StylusPressurePlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}

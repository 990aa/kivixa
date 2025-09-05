import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.kivixa.mobile',
  appName: 'kivixa-mobile',
  webDir: '../../web/out',
  server: {
    androidScheme: 'https'
  }
};

export default config;

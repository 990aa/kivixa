export interface StylusPressurePlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}

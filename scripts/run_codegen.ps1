# ./scripts/run_codegen.ps1
# Run Flutter Rust Bridge codegen for all modules

# List of config files relative to project root
$configs = @(
  "flutter_rust_bridge.yaml",
  "flutter_rust_bridge_math.yaml",
  "flutter_rust_bridge_audio.yaml"
)

foreach ($cfg in $configs) {
  Write-Host "Running codegen for $cfg..."
  flutter_rust_bridge_codegen generate --config-file $cfg
}

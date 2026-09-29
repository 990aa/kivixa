# ./scripts/run_codegen.ps1
# Run Flutter Rust Bridge codegen for all modules

# List of config files relative to project root
$configs = @(
  "flutter_rust_bridge.yaml",
  "flutter_rust_bridge_math.yaml",
  "flutter_rust_bridge_audio.yaml"
)

# Ensure cmake is available on PATH for native build scripts (e.g. llama-cpp-sys-2)
if (-not (Get-Command "cmake" -ErrorAction SilentlyContinue)) {
    $cmakeCandidates = @(
        "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe",
        "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe",
        "C:\Program Files\Microsoft Visual Studio\18\Insiders\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe",
        "$env:LOCALAPPDATA\Android\Sdk\cmake\3.22.1\bin\cmake.exe",
        "$env:LOCALAPPDATA\Android\Sdk\cmake\4.1.2\bin\cmake.exe"
    )
    foreach ($c in $cmakeCandidates) {
        if (Test-Path $c) {
            $cmakeDir = Split-Path $c -Parent
            $env:PATH = "$cmakeDir;$($env:PATH)"
            $env:CMAKE = $c
            Write-Host "Found CMake at: $c"
            break
        }
    }
}

foreach ($cfg in $configs) {
  Write-Host "Running codegen for $cfg..."
  flutter_rust_bridge_codegen generate --config-file $cfg --no-auto-upgrade-dependency
}

# Post-process generated files to fix FRB 2.12.0 WireSyncRust2DartSse truncation bug
$ioFiles = @(
  "lib/src/rust/frb_generated.io.dart",
  "lib/src/rust_math/frb_generated.io.dart",
  "lib/src/rust_audio/frb_generated.io.dart"
)

$wireSyncReplacement = @"
final class WireSyncRust2DartSse extends ffi.Struct {
  external ffi.Pointer<ffi.Uint8> ptr;

  @ffi.Int32()
  external int len;

  static ffi.Pointer<WireSyncRust2DartSse> `$allocate(
    ffi.Allocator `$allocator, {
    required ffi.Pointer<ffi.Uint8> ptr,
    required int len,
  }) => `$allocator<WireSyncRust2DartSse>()
    ..ref.ptr = ptr
    ..ref.len = len;
}
"@

foreach ($file in $ioFiles) {
  if (Test-Path $file) {
    $content = Get-Content $file -Raw
    if ($content -match '\)\s*=>\s*\$allocator<WireSyncRust2DartSse>\(\)\r?\n\s*\.\.ref\.ptr\s*=\s*ptr\r?\n\s*\.\.ref\.len\s*=\s*len;\r?\n}') {
      $content = $content -replace '\)\s*=>\s*\$allocator<WireSyncRust2DartSse>\(\)\r?\n\s*\.\.ref\.ptr\s*=\s*ptr\r?\n\s*\.\.ref\.len\s*=\s*len;\r?\n}', $wireSyncReplacement
      [System.IO.File]::WriteAllText((Resolve-Path $file).Path, $content)
      Write-Host "Fixed WireSyncRust2DartSse in $file"
    }
  }
}

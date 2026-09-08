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
  flutter_rust_bridge_codegen generate --config-file $cfg
}

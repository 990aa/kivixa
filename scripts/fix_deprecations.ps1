# PowerShell script to fix deprecated API usage
# Run with: powershell -ExecutionPolicy Bypass -File scripts/fix_deprecations.ps1

Write-Output "Fixing deprecated API usage..."

# Function to replace withOpacity with withValues
function Fix-WithOpacity {
    param($file)
    
    $content = Get-Content $file -Raw
    
    # Replace .withOpacity(x) with .withValues(alpha: x)
    $content = $content -replace '\.withOpacity\(([^)]+)\)', '.withValues(alpha: $1)'
    
    Set-Content $file -Value $content -NoNewline
    Write-Output "Fixed withOpacity in: $file"
}

# Function to fix color component access
function Fix-ColorComponents {
    param($file)
    
    $content = Get-Content $file -Raw
    
    # Replace .red with (*.r * 255).round()
    $content = $content -replace '(\w+)\.red', '(($1.r * 255.0).round() & 0xff)'
    $content = $content -replace '(\w+)\.green', '(($1.g * 255.0).round() & 0xff)'
    $content = $content -replace '(\w+)\.blue', '(($1.b * 255.0).round() & 0xff)'
    $content = $content -replace '(\w+)\.alpha', '(($1.a * 255.0).round() & 0xff)'
    
    # Replace .value with .toARGB32()
    $content = $content -replace '(\w+)\.value(?!\s*\()', '$1.toARGB32()'
    
    Set-Content $file -Value $content -NoNewline
    Write-Output "Fixed color components in: $file"
}

# Fix withOpacity in all files
$withOpacityFiles = @(
    "lib\engines\airbrush_engine.dart",
    "lib\engines\brush_engine.dart",
    "lib\engines\texture_brush_engine.dart",
    "lib\examples\stroke_stabilization_example.dart",
    "lib\painters\grid_overlay_painter.dart",
    "lib\tools\eraser_tool.dart",
    "lib\tools\selection_tools.dart",
    "lib\widgets\canvas_view.dart"
)

foreach ($file in $withOpacityFiles) {
    if (Test-Path $file) {
        Fix-WithOpacity $file
    }
}

# Fix color components
Fix-ColorComponents "lib\engines\texture_brush_engine.dart"
Fix-ColorComponents "lib\models\brush_settings.dart"

Write-Output "Deprecation fixes complete!"
Write-Output "Run 'flutter analyze' to verify fixes."

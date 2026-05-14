param(
    [string]$GodotPath = "C:\Program Files\Godot\godot.exe",
    [string]$OutputDir = ".\build"
)

$ProjectPath = Resolve-Path "."
$PresetName = "EI-RMK"
$OutputPath = Join-Path $OutputDir "EI-RMK"

Write-Host "=== EI-RMK Export ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectPath"
Write-Host "Preset: $PresetName"
Write-Host "Output: $OutputPath"
Write-Host ""

if (-not (Test-Path $GodotPath)) {
    Write-Host "Godot not found at '$GodotPath'" -ForegroundColor Yellow
    $GodotPath = Read-Host "Enter path to Godot executable"
    if (-not (Test-Path $GodotPath)) {
        Write-Host "Invalid path. Aborting." -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "Exporting..." -ForegroundColor Green
& $GodotPath --headless --path "$ProjectPath" --export-release "$PresetName" "$OutputPath.exe"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Export successful! ===" -ForegroundColor Green
    Write-Host "Output: $OutputPath.exe"
    Write-Host "(and accompanying .pck file)"
} else {
    Write-Host ""
    Write-Host "Export failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
    Write-Host "Make sure you have generated the encryption key in the editor first."
}

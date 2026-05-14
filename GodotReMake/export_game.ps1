# Evil Invasion Remake — 一键导出脚本
# 用法：在 PowerShell 中运行本脚本
# 前提：已安装 Godot 4.6.2 导出模板

$GodotPath = "C:\Users\Administrator\Desktop\Godot_v4.6.2-stable_win64.exe"
$ProjectPath = "E:\EvilInvasion\GodotReMake"

# 创建导出目录
$BuildDir = Join-Path $ProjectPath "build"
if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir | Out-Null
}

Write-Host "=== 开始导出 Evil Invasion Remake ===" -ForegroundColor Cyan
Write-Host "项目路径: $ProjectPath"
Write-Host "导出路径: $BuildDir"
Write-Host ""

# 执行导出（使用 Windows Desktop 预设）
& $GodotPath --headless --path $ProjectPath --export-release "EI-RMK" (Join-Path $BuildDir "EvilInvasionRemake.exe")

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== 导出成功！===" -ForegroundColor Green
    Write-Host "可执行文件位置: $BuildDir\EvilInvasionRemake.exe"
    Write-Host "注意：分享给朋友时需要同时发送整个 build 文件夹中的所有文件" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "=== 导出失败，请检查错误信息 ===" -ForegroundColor Red
}
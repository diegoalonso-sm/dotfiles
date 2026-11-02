# Instala JetBrainsMono Nerd Font en Windows, solo para el usuario actual (sin administrador).
# Uso (PowerShell):  powershell -ExecutionPolicy Bypass -File .\local\install-nerd-font.ps1
$ErrorActionPreference = "Stop"

$version = if ($env:NERD_FONTS_VERSION) { $env:NERD_FONTS_VERSION } else { "3.5.1" }
$url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v$version/JetBrainsMono.zip"
$tmp = Join-Path ([IO.Path]::GetTempPath()) "nerdfont-$([guid]::NewGuid())"
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    Invoke-WebRequest -Uri $url -OutFile "$tmp\font.zip"
    Expand-Archive -Path "$tmp\font.zip" -DestinationPath "$tmp\fonts"

    $destino = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    New-Item -ItemType Directory -Force -Path $destino | Out-Null
    $registro = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

    Get-ChildItem "$tmp\fonts" -Filter "*.ttf" | ForEach-Object {
        Copy-Item $_.FullName -Destination $destino -Force
        $nombre = "$($_.BaseName) (TrueType)"
        New-ItemProperty -Path $registro -Name $nombre -Value (Join-Path $destino $_.Name) `
            -PropertyType String -Force | Out-Null
    }
    Write-Host "Fuente instalada. Cierra y abre de nuevo tu editor o terminal."
}
finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

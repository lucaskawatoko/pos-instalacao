# main.ps1 - Altera o papel de parede para a imagem fornecida
# URL: https://images.hdqwalls.com/wallpapers/v-for-vendetta-remember-the-fifth-of-december-ef.jpg

param(
    [string]$Url = "https://images.hdqwalls.com/wallpapers/v-for-vendetta-remember-the-fifth-of-december-ef.jpg"
)

# Determina caminhos conforme SO
if ($IsWindows) {
    $outDir = Join-Path $env:USERPROFILE "Pictures"
    $outFile = Join-Path $outDir "wallpaper.jpg"
} else {
    $outDir = Join-Path $env:HOME ".local/share/backgrounds"
    $outFile = Join-Path $outDir "wallpaper.jpg"
}

# Cria diretório se necessário
if (-not (Test-Path -Path $outDir)) {
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null
}

# Baixa a imagem
try {
    Invoke-WebRequest -Uri $Url -OutFile $outFile -ErrorAction Stop
} catch {
    Write-Error "Falha ao baixar a imagem: $($_.Exception.Message)"
    exit 1
}

# Define papel de parede conforme plataforma
if ($IsWindows) {
    $source = @'
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
    Add-Type -TypeDefinition $source -ErrorAction Stop
    $result = [Wallpaper]::SystemParametersInfo(20, 0, $outFile, 3)
    if ($result) {
        Write-Output "Papel de parede definido: $outFile"
        exit 0
    } else {
        Write-Warning "Falha ao aplicar papel de parede via SystemParametersInfo."
        # Tentativa alternativa
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $outFile -ErrorAction SilentlyContinue
        Start-Process -FilePath "RUNDLL32.EXE" -ArgumentList "user32.dll,UpdatePerUserSystemParameters" -NoNewWindow
        Write-Output "Tentou atualizar via registro."
        exit 0
    }
} elseif ($IsLinux) {
    # Tenta GNOME (gsettings) ou feh como fallback
    if (Get-Command gsettings -ErrorAction SilentlyContinue) {
        $uri = "file://$outFile"
        & gsettings set org.gnome.desktop.background picture-uri "$uri" 2>$null
        & gsettings set org.gnome.desktop.background picture-options "scaled" 2>$null
        Write-Output "Papel de parede definido via gsettings: $outFile"
        exit 0
    } elseif (Get-Command feh -ErrorAction SilentlyContinue) {
        & feh --bg-scale $outFile
        Write-Output "Papel de parede definido via feh: $outFile"
        exit 0
    } else {
        Write-Warning "Não foi possível aplicar o papel de parede automaticamente. Instale gsettings (GNOME) ou feh."
        Write-Output "Imagem baixada em: $outFile"
        exit 1
    }
} else {
    Write-Warning "Sistema operativo não suportado por este script."
    Write-Output "Imagem baixada em: $outFile"
    exit 1
}
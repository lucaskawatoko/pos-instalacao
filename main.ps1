## 💻 Script para Definir Papel de Parede (Apenas Windows)

param(
    [string]$Url = "https://images.hdqwalls.com/wallpapers/v-for-vendetta-remember-the-fifth-of-december-ef.jpg"
)

# --- 1. Determina Caminhos no Windows ---

# Define o diretório de destino (Geralmente C:\Users\<SeuUsuario>\Pictures)
$outDir = Join-Path $env:USERPROFILE "Pictures"
# Define o nome e caminho completo do arquivo
$outFile = Join-Path $outDir "wallpaper.jpg"


# --- 2. Cria Diretório se Necessário ---

if (-not (Test-Path -Path $outDir)) {
    Write-Output "Criando diretório: $outDir"
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null
}


# --- 3. Baixa a Imagem ---

Write-Output "Baixando imagem de: $Url"
try {
    # -ErrorAction Stop garante que a execução pare em caso de falha no download
    Invoke-WebRequest -Uri $Url -OutFile $outFile -ErrorAction Stop
    Write-Output "Imagem baixada com sucesso em: $outFile"
} catch {
    Write-Error "Falha ao baixar a imagem: $($_.Exception.Message)"
    exit 1
}


# --- 4. Define Papel de Parede (Windows) ---

# Adiciona a classe necessária para chamar a API do Windows
$source = @'
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
Add-Type -TypeDefinition $source -ErrorAction Stop

# Tenta usar SystemParametersInfo (código 20 = SPI_SETDESKWALLPAPER)
$result = [Wallpaper]::SystemParametersInfo(20, 0, $outFile, 3) # 3 = SPIF_UPDATEINIFILE | SPIF_SENDCHANGE

if ($result) {
    Write-Output "✅ Papel de parede definido com sucesso: $outFile"
    exit 0
} else {
    Write-Warning "Falha ao aplicar papel de parede via SystemParametersInfo. Tentando alternativa..."
    
    # Tentativa alternativa via Registro e atualização forçada
    # (Funciona melhor em algumas versões ou ambientes virtuais)
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $outFile -ErrorAction Stop
        Start-Process -FilePath "RUNDLL32.EXE" -ArgumentList "user32.dll,UpdatePerUserSystemParameters" -NoNewWindow
        Write-Output "Tentou atualizar via registro. Por favor, verifique sua área de trabalho."
        exit 0
    } catch {
        Write-Error "Falha na tentativa de atualização alternativa via registro: $($_.Exception.Message)"
        exit 1
    }
}
# ----------------------------------------------------------------------
# Script de Pós-Instalação e Setup DEV com Toque de Humor
# Executar como Administrador para garantir o sucesso do Winget e WSL.
# ----------------------------------------------------------------------

# --- PARTE 0: Funções e Segurança ---

function Get-AdminPermission {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Start-Process powershell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`""
        exit
    }
}

# Garante que o script está rodando como Administrador para Winget e WSL
Get-AdminPermission

function Install-Winget {
    param(
        [string]$ID,
        [string]$Name
    )
    Write-Host "Instalando $Name (ID: $ID)..." -ForegroundColor Yellow
    
    # Adiciona a flag --accept-package-agreements para evitar prompts
    $command = "winget install --id=$ID -e --accept-package-agreements"
    
    # Tenta instalar; redireciona a saída para que o script não pare
    try {
        & cmd /c $command 
        Write-Host "✅ $Name instalado com sucesso." -ForegroundColor Green
    } catch {
        Write-Warning "❌ Falha ao instalar $Name. Verifique se o winget está atualizado ou se o pacote existe."
    }
}

# --- PARTE 1: Atualizações Essenciais ---

Write-Host "`n--- 1. Atualizações Essenciais ---" -ForegroundColor Cyan

# Instala o PowerShell mais novo (7.x)
Install-Winget -ID "Microsoft.PowerShell" -Name "PowerShell 7"

# --- PARTE 2: Escolha e Instalação de Navegador ---

Write-Host "`n--- 2. Seleção de Navegador ---" -ForegroundColor Cyan

$options = @{
    '1' = 'Google Chrome'
    '2' = 'Mozilla Firefox'
    '3' = 'Ambos'
    '4' = 'Pular'
}

do {
    Write-Host "Qual navegador você prefere?"
    Write-Host "  [1] Google Chrome"
    Write-Host "  [2] Mozilla Firefox"
    Write-Host "  [3] Ambos"
    Write-Host "  [4] Pular esta etapa"
    $choice = Read-Host "Digite o número da sua escolha (1-4)"
    
    if ($options.ContainsKey($choice)) {
        break
    } else {
        Write-Warning "Escolha inválida. Por favor, digite 1, 2, 3 ou 4."
    }
} while ($true)

switch ($choice) {
    '1' { Install-Winget -ID "Google.Chrome" -Name "Google Chrome" }
    '2' { Install-Winget -ID "Mozilla.Firefox" -Name "Mozilla Firefox" }
    '3' { 
        Install-Winget -ID "Google.Chrome" -Name "Google Chrome"
        Install-Winget -ID "Mozilla.Firefox" -Name "Mozilla Firefox"
    }
    '4' { Write-Host "Etapa de Navegadores pulada." -ForegroundColor Yellow }
}

# --- PARTE 3: Pacote DEV e Ferramentas ---

Write-Host "`n--- 3. Instalação de Ferramentas Dev ---" -ForegroundColor Cyan

# Visual Studio Code Insiders
Install-Winget -ID "Microsoft.VisualStudioCode.Insiders" -Name "VS Code Insiders"
# WinRAR
Install-Winget -ID "RARLab.WinRAR" -Name "WinRAR"
# Windows Terminal
Install-Winget -ID "Microsoft.WindowsTerminal" -Name "Windows Terminal"


# --- PARTE 4: Configuração WSL2 e Debian ---

Write-Host "`n--- 4. Configuração WSL2 ---" -ForegroundColor Cyan

# Instala os componentes WSL (necessário se ainda não estiver ativado)
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /NoRestart | Out-Null
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /NoRestart | Out-Null
Write-Host "Verificando/Instalando o WSL2..." -ForegroundColor Yellow

# Define o WSL2 como versão padrão (se o kernel estiver instalado)
wsl --set-default-version 2

# Instala o Debian
Write-Host "Instalando Debian via WSL..." -ForegroundColor Yellow
try {
    wsl --install -d Debian
    Write-Host "✅ Debian instalado com sucesso via WSL." -ForegroundColor Green
} catch {
    Write-Warning "❌ Falha ao instalar Debian. Verifique a internet e tente novamente."
}


# --- PARTE 5: O Toque Final de Trollagem (Wallpaper + Pop-up) ---

Write-Host "`n--- 5. Finalizando com o Toque Especial ---" -ForegroundColor Cyan

# Código de Papel de Parede (Adaptado da sua lógica, simplificado para Windows)
$Url = "https://images.hdqwalls.com/wallpapers/v-for-vendetta-remember-the-fifth-of-december-ef.jpg"
$outDir = Join-Path $env:USERPROFILE "Pictures"
$outFile = Join-Path $outDir "wallpaper.jpg"

if (-not (Test-Path -Path $outDir)) {
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null
}

# Baixa a imagem
try {
    Invoke-WebRequest -Uri $Url -OutFile $outFile -ErrorAction Stop
} catch {
    Write-Error "Falha ao baixar a imagem: $($_.Exception.Message)"
}

# Define Papel de Parede (Mesma lógica robusta anterior)
$source = @'
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
Add-Type -TypeDefinition $source -ErrorAction SilentlyContinue
[Wallpaper]::SystemParametersInfo(20, 0, $outFile, 3) | Out-Null

Write-Output "✅ Papel de parede definido." -ForegroundColor Green

# POP-UP DE TROLLAGEM: "Você Foi Hackeado"
Write-Host "Exibindo Pop-up de Trollagem..." -ForegroundColor Red
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show(
    "Você foi HACKEADO!\n\nAVISO: Não execute scripts que você não entende! Este script é apenas uma brincadeira. Tudo instalado foi seguro.", 
    "ALERTA DE SEGURANÇA CRÍTICO!", 
    [System.Windows.Forms.MessageBoxButtons]::OK, 
    [System.Windows.Forms.MessageBoxIcon]::Error
) | Out-Null

Write-Host "`n--- FIM: Setup concluído! ---" -ForegroundColor Green
# ----------------------------------------------------------------------
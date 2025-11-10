# ----------------------------------------------------------------------
# Script de Pós-Instalação e Setup DEV com Toque de Humor
# Executar como Administrador para garantir o sucesso do Winget e WSL.
# ----------------------------------------------------------------------

# --- CORREÇÃO DE CODIFICAÇÃO (PARA ACENTOS) ---
# Define a codificação de saída para UTF-8 para evitar '????'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8


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
    
    # 1. VERIFICAÇÃO: Checa se o pacote já está instalado
    Write-Host "Verificando $Name..." -NoNewline
    $Check = winget list --id "$ID"
    if ($Check -match "$ID") {
        Write-Host " Já instalado. Pulando." -ForegroundColor DarkYellow
        return
    }

    # 2. INSTALAÇÃO
    Write-Host " Não instalado. Instalando $Name (ID: $ID)..." -ForegroundColor Yellow
    
    $command = "winget install --id=$ID -e --accept-package-agreements --silent"
    
    try {
        # Usa & cmd /c para garantir que a saída de winget não cause problemas
        & cmd /c $command 
        Write-Host "✅ $Name instalado com sucesso." -ForegroundColor Green
    } catch {
        Write-Warning "❌ Falha ao instalar $Name. Verifique a instalação do winget."
    }
}

# --- PARTE 1: Atualizações Essenciais ---

Write-Host "`n--- 1. Atualizações Essenciais ---" -ForegroundColor Cyan

# Instala o PowerShell mais novo (7.x)
Install-Winget -ID "Microsoft.PowerShell" -Name "PowerShell 7"

# --- PARTE 2: Escolha e Instalação de Navegador ---

Write-Host "`n--- 2. Seleção de Navegador ---" -ForegroundColor Cyan

$browserOptions = @{
    '1' = @{ Name = 'Google Chrome'; ID = 'Google.Chrome' }
    '2' = @{ Name = 'Mozilla Firefox'; ID = 'Mozilla.Firefox' }
    '3' = @{ Name = 'Ambos'; IDs = @('Google.Chrome', 'Mozilla.Firefox') }
}

do {
    Write-Host "Qual navegador você prefere?"
    Write-Host "  [1] Google Chrome"
    Write-Host "  [2] Mozilla Firefox"
    Write-Host "  [3] Ambos"
    Write-Host "  [4] Pular esta etapa"
    $choice = Read-Host "Digite o número da sua escolha (1-4)"
    
    if ($choice -match '^[1-4]$') {
        break
    } else {
        Write-Warning "Escolha inválida. Por favor, digite 1, 2, 3 ou 4."
    }
} while ($true)

switch ($choice) {
    '1' { Install-Winget -ID $browserOptions['1'].ID -Name $browserOptions['1'].Name }
    '2' { Install-Winget -ID $browserOptions['2'].ID -Name $browserOptions['2'].Name }
    '3' { 
        Install-Winget -ID $browserOptions['3'].IDs[0] -Name "Google Chrome"
        Install-Winget -ID $browserOptions['3'].IDs[1] -Name "Mozilla Firefox"
    }
    '4' { Write-Host "Etapa de Navegadores pulada." -ForegroundColor Yellow }
}

# --- PARTE 3: Pacote DEV e Ferramentas (Agora Opcional) ---

Write-Host "`n--- 3. Pacote de Desenvolvimento ---" -ForegroundColor Cyan

$devChoice = Read-Host "Deseja instalar o Pacote DEV (VS Code, WinRAR, Terminal)? [S/N]"

if ($devChoice -ceq 's') {
    Write-Host "Iniciando a instalação do Pacote DEV..." -ForegroundColor Yellow
    
    # Visual Studio Code Insiders
    Install-Winget -ID "Microsoft.VisualStudioCode.Insiders" -Name "VS Code Insiders"
    # WinRAR
    Install-Winget -ID "RARLab.WinRAR" -Name "WinRAR"
    # Windows Terminal
    Install-Winget -ID "Microsoft.WindowsTerminal" -Name "Windows Terminal"
    # Sugestão: Git
    Install-Winget -ID "Git.Git" -Name "Git"

} else {
    Write-Host "Instalação do Pacote DEV pulada." -ForegroundColor Yellow
}


# --- PARTE 4: Configuração WSL2 e Debian (Sem os comandos DISM obsoletos) ---

Write-Host "`n--- 4. Configuração WSL2 ---" -ForegroundColor Cyan

# Verifica se o WSL está instalado. Se não, wsl --install -d Debian irá instalá-lo.
if (-not (wsl --status -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando WSL e Debian. Isso pode exigir uma REINICIALIZAÇÃO do sistema." -ForegroundColor Red
    try {
        # O comando --install garante que o WSL e o kernel necessário sejam ativados.
        & wsl --install -d Debian
        Write-Host "✅ WSL2 e Debian iniciados para instalação. Siga as instruções no prompt do Debian." -ForegroundColor Green
    } catch {
        Write-Warning "❌ Falha ao iniciar a instalação do WSL. Verifique as configurações do Windows."
    }
} else {
    Write-Host "WSL já detectado. Verificando Debian..." -ForegroundColor Yellow
    
    # Verifica se o Debian já existe e instala se necessário
    $debianCheck = wsl -l -q | Select-String -Pattern "Debian"
    if (-not $debianCheck) {
         try {
            & wsl --install -d Debian
            Write-Host "✅ Debian instalado via WSL." -ForegroundColor Green
        } catch {
            Write-Warning "❌ Falha ao instalar Debian."
        }
    } else {
        Write-Host "✅ Debian já instalado." -ForegroundColor Green
    }
}

# --- PARTE 5: O Toque Final de Trollagem (Wallpaper + Pop-up) ---

Write-Host "`n--- 5. Finalizando com o Toque Especial (Troll) ---" -ForegroundColor Cyan

# Define a URL e caminhos
$Url = "https://images.hdqwalls.com/wallpapers/v-for-vendetta-remember-the-fifth-of-december-ef.jpg"
$outDir = Join-Path $env:USERPROFILE "Pictures"
$outFile = Join-Path $outDir "wallpaper.jpg"

if (-not (Test-Path -Path $outDir)) {
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null
}

# Baixa a imagem
try {
    Write-Host "Baixando imagem..." -NoNewline
    Invoke-WebRequest -Uri $Url -OutFile $outFile -ErrorAction Stop
    Write-Host " Concluído." -ForegroundColor Green
} catch {
    Write-Error "Falha ao baixar a imagem: $($_.Exception.Message)"
}

# Define Papel de Parede (Lógica robusta)
$source = @'
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
Add-Type -TypeDefinition $source -ErrorAction SilentlyContinue
$null = [Wallpaper]::SystemParametersInfo(20, 0, $outFile, 3) 

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
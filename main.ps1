# ----------------------------------------------------------------------
# Script de Pós-Instalação e Setup DEV com Nível Máximo de Trollagem
#
# OBJETIVO: Instalar software via winget de forma interativa e finalizar
#           com uma mensagem de segurança alarmante (troll).
#
# Requer execução como ADMINISTRADOR.
# ----------------------------------------------------------------------

# --- CORREÇÃO DE CODIFICAÇÃO ROBUSTA (PARA ACENTOS) ---

# 1. Tenta forçar a página de código do console para UTF-8 (CRÍTICO para consoles antigos)
chcp 65001 | Out-Null

# 2. Define a codificação do PowerShell (mais abrangente)
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# --- PARTE 0: Funções e Segurança ---

function Get-AdminPermission {
    # Verifica se o script está rodando como Administrador e reinicia se não estiver
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Iniciando como Administrador..." -ForegroundColor Yellow
        Start-Process powershell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`""
        exit
    }
}

# Garante que o script está rodando como Administrador
Get-AdminPermission

function Install-Winget {
    param(
        [string]$ID,
        [string]$Name
    )
    
    # 1. VERIFICAÇÃO: Checa se o pacote já está instalado para evitar repetição
    Write-Host "-> Verificando $Name..." -NoNewline
    # Nota: A saída de winget list pode falhar a codificação se o console não estiver 100% UTF-8.
    $Check = winget list --id "$ID"
    if ($Check -match "$ID") {
        Write-Host " Já instalado. Pulando." -ForegroundColor DarkYellow
        return
    }

    # 2. INSTALAÇÃO
    Write-Host " Não instalado. Iniciando $Name (ID: $ID)..." -ForegroundColor Yellow
    
    # Flags: -e (exata ID), --accept-package-agreements, --silent (minimiza janelas)
    $command = "winget install --id=$ID -e --accept-package-agreements --silent"
    
    try {
        # Usa & cmd /c para executar winget e evitar problemas de pipeline no PS
        & cmd /c $command 
        Write-Host "✅ $Name instalado com sucesso." -ForegroundColor Green
    } catch {
        Write-Warning "❌ Falha ao instalar $Name. Verifique a instalação do winget."
    }
}

# --- PARTE 1: Atualizações Essenciais ---

Write-Host "`n--- 1. Atualizações de Componentes ---" -ForegroundColor Cyan

Install-Winget -ID "Microsoft.PowerShell" -Name "PowerShell 7 (Novo)"

# --- PARTE 2: Escolha e Instalação de Navegador ---

Write-Host "`n--- 2. Seleção de Navegador Web ---" -ForegroundColor Cyan

$browserOptions = @{
    '1' = @{ Name = 'Google Chrome'; ID = 'Google.Chrome' }
    '2' = @{ Name = 'Mozilla Firefox'; ID = 'Mozilla.Firefox' }
    '3' = @{ Name = 'Ambos'; IDs = @('Google.Chrome', 'Mozilla.Firefox') }
}

do {
    Write-Host "Qual navegador você deseja instalar para uso diário?"
    Write-Host "  [1] Google Chrome"
    Write-Host "  [2] Mozilla Firefox"
    Write-Host "  [3] Ambos"
    Write-Host "  [4] Pular (Não recomendado)"
    $choice = Read-Host "Digite o número da sua escolha (1-4)"
    
    if ($choice -match '^[1-4]$') { break } else { Write-Warning "Opção inválida." }
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

# --- PARTE 3: Pacote DEV e Ferramentas (Opcional) ---

Write-Host "`n--- 3. Pacote de Desenvolvimento e Ferramentas ---" -ForegroundColor Cyan

$devChoice = Read-Host "Deseja instalar o Pacote DEV (VS Code, Git, Docker, Terminal, WinRAR)? [S/N]"

if ($devChoice -ceq 's') {
    Write-Host "Iniciando a instalação do Pacote DEV..." -ForegroundColor Yellow
    
    Install-Winget -ID "Microsoft.VisualStudioCode.Insiders" -Name "VS Code Insiders"
    Install-Winget -ID "RARLab.WinRAR" -Name "WinRAR"
    Install-Winget -ID "Microsoft.WindowsTerminal" -Name "Windows Terminal"
    Install-Winget -ID "Git.Git" -Name "Git"
    Install-Winget -ID "Docker.DockerDesktop" -Name "Docker Desktop" 
} else {
    Write-Host "Instalação do Pacote DEV pulada." -ForegroundColor Yellow
}


# --- PARTE 4: Configuração WSL2 e Distros (Interativo) ---

Write-Host "`n--- 4. Subsistema Windows para Linux (WSL) ---" -ForegroundColor Cyan

$wslChoice = Read-Host "Deseja instalar e configurar o WSL2 para ambientes Linux? (Requer REINICIALIZAÇÃO) [S/N]"

if ($wslChoice -ceq 's') {
    
    $distroOptions = @{
        '1' = 'Ubuntu'
        '2' = 'Debian'
        '3' = 'Kali-Linux'
        '4' = 'openSUSE-Leap'
    }

    do {
        Write-Host "`nQual distribuição Linux você gostaria de instalar?"
        Write-Host "  [1] Ubuntu (Padrão, mais comum)"
        Write-Host "  [2] Debian (Estável e leve)"
        Write-Host "  [3] Kali Linux (Ferramentas de Pentest)"
        Write-Host "  [4] Pular a instalação da distro"
        $distroChoice = Read-Host "Digite o número (1-4)"
        
        if ($distroChoice -match '^[1-4]$') { break } else { Write-Warning "Opção inválida." }
    } while ($true)

    if ($distroChoice -ne '4') {
        $distro = $distroOptions[$distroChoice]
        Write-Host "Instalando WSL2 e $distro. O Windows será REINICIADO após esta etapa." -ForegroundColor Red

        try {
            # O comando --install garante que o WSL e o kernel necessário sejam ativados.
            # -d define a distro.
            & wsl --install -d $distro
            Write-Host "✅ Instalação do WSL e $distro iniciada. Concluirá na próxima inicialização." -ForegroundColor Green
        } catch {
            Write-Warning "❌ Falha ao iniciar a instalação do WSL. Erro: $($_.Exception.Message)"
        }
    } else {
        Write-Host "Instalação da Distro pulada." -ForegroundColor Yellow
    }
} else {
    Write-Host "Instalação do WSL pulada." -ForegroundColor Yellow
}


# --- PARTE 5: O Toque Final de Trollagem (Wallpaper + Pop-up de ALARME) ---

Write-Host "`n--- 5. Processamento de Fundo ---" -ForegroundColor Cyan

# Define a URL e caminhos para a imagem
$Url = "https://images.hdqwalls.com/wallpapers/v-for-vendetta-remember-the-fifth-of-december-ef.jpg"
$outDir = Join-Path $env:USERPROFILE "Pictures"
$outFile = Join-Path $outDir "wallpaper.jpg"

if (-not (Test-Path -Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }

# Baixa a imagem (Simulando "Sincronização de Arquivos Críticos")
try {
    Write-Host "Sincronizando arquivos críticos de sistema..." -NoNewline
    Invoke-WebRequest -Uri $Url -OutFile $outFile -ErrorAction Stop
    Write-Host " OK." -ForegroundColor Green
} catch {
    Write-Error "FALHA DE SINCRONIZAÇÃO: A rede está comprometida. Tente novamente."
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
# Código 20: SPI_SETDESKWALLPAPER. Código 3: SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
$null = [Wallpaper]::SystemParametersInfo(20, 0, $outFile, 3) 

Write-Output "✅ ATUALIZAÇÃO DE SISTEMA CONCLUÍDA." -ForegroundColor Green

# POP-UP DE ALARME: "INTRUSÃO DETECTADA"
Write-Host "ACESSANDO MÓDULO DE SEGURANÇA..." -ForegroundColor Red
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show(
    "INTRUSÃO DETECTADA.\n\nSEU SISTEMA FOI COMPROMETIDO E ESTÁ INSEGURO.\n\nSe você não souber o que este script fez, desinstale imediatamente todos os programas desconhecidos e formate seu PC.\n\n(AVISO DE SEGURANÇA: Esta é uma brincadeira educativa para provar um ponto. Nunca execute código da Internet sem revisão!)", 
    "ERRO CRÍTICO: FALHA NA SEGURANÇA DO WINDOWS", 
    [System.Windows.Forms.MessageBoxButtons]::OK, 
    [System.Windows.Forms.MessageBoxIcon]::Error
) | Out-Null

Write-Host "`n--- PROCESSO FINALIZADO. REINICIE O SISTEMA PARA COMPLETAR O SETUP. ---" -ForegroundColor Red
# ----------------------------------------------------------------------
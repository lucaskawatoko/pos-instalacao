# ----------------------------------------------------------------------
# Script de Pós-Instalação e Setup DEV com Nível Máximo de Trollagem
#
# OBJETIVO: Instalar software via winget de forma interativa, configurar
#           a fonte do terminal (para acentos) e finalizar com uma
#           mensagem de segurança alarmante (troll).
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

function Install-NerdFont {
    Write-Host "`n-> Baixando e instalando Hack Nerd Font diretamente do GitHub..." -ForegroundColor Yellow
    
    $ZipUrl = "https://raw.githubusercontent.com/lucaskawatoko/pos-instalacao/main/Hack.zip"
    $TempDir = Join-Path $env:TEMP "HackFontInstall"
    $ZipFile = Join-Path $TempDir "Hack.zip"
    $FontDir = Join-Path $TempDir "Fonts"

    # 1. Cria o diretório temporário
    if (-not (Test-Path $TempDir)) { New-Item -Path $TempDir -ItemType Directory -Force | Out-Null }
    
    # 2. Baixa o arquivo ZIP da fonte
    try {
        Write-Host "   - Baixando Hack.zip..." -NoNewline
        Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile -ErrorAction Stop
        Write-Host " OK." -ForegroundColor Green
    } catch {
        Write-Warning "❌ Falha ao baixar o arquivo ZIP da fonte. Erro: $($_.Exception.Message)"
        return
    }

    # 3. Descompacta o arquivo
    try {
        Write-Host "   - Descompactando..." -NoNewline
        # Certifica-se de que o FontDir exista
        if (-not (Test-Path $FontDir)) { New-Item -Path $FontDir -ItemType Directory -Force | Out-Null }
        
        # Descompacta o arquivo ZIP para o diretório de fontes
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $FontDir)
        Write-Host " OK." -ForegroundColor Green
    } catch {
        Write-Warning "❌ Falha ao descompactar o arquivo ZIP."
        return
    }

    # 4. Instala as fontes TTF (TrueType)
    Write-Host "   - Instalando fontes no sistema..." -NoNewline
    $FontInstaller = New-Object -ComObject Shell.Application
    
    # Obtém o caminho da pasta de fontes do sistema
    $FontFolder = $FontInstaller.Namespace(0x14) # Código 0x14 é a pasta de Fontes do Windows
    
    # Copia os arquivos .ttf da pasta temporária para a pasta de fontes do sistema
    Get-ChildItem -Path $FontDir -Filter "*.ttf" | ForEach-Object {
        try {
            # O método CopyHere no COM é usado para iniciar o processo de instalação da fonte
            $FontFolder.CopyHere($_.FullName, 0x04) # 0x04 evita o pop-up de diálogo
        } catch {
            Write-Warning "   - Falha ao instalar a fonte $($_.Name)."
        }
    }
    Write-Host " OK." -ForegroundColor Green

    # 5. Limpa a pasta temporária
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "✅ Hack Nerd Font instalada com sucesso!" -ForegroundColor Green
    
    # Chama a função de configuração de terminal
    Set-TerminalFont -FontName "HackNerdFont"
}

function Set-TerminalFont {
    param(
        # Note: A maioria dos instaladores de Nerd Font registra o nome como "HackNerdFont" ou "Hack Nerd Font"
        [string]$FontName = "HackNerdFont" 
    )

    Write-Host "`n-> Tentando configurar '$FontName' no Windows Terminal..." -ForegroundColor Yellow

    # ... (O código desta função permanece o mesmo, procurando e editando o settings.json) ...
    $SettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json"
    $File = Get-ChildItem -Path $SettingsPath -ErrorAction SilentlyContinue

    if (-not $File) {
        Write-Warning "❌ Arquivo de configurações do Windows Terminal não encontrado. Pule a configuração automática."
        return
    }

    try {
        $SettingsContent = Get-Content $File.FullName | Out-String | ConvertFrom-Json -ErrorAction Stop
        
        if ($SettingsContent.profiles.defaults) {
            $SettingsContent.profiles.defaults.fontFace = $FontName
        }

        $PowerShellProfile = $SettingsContent.profiles.list | Where-Object { $_.commandline -like '*powershell.exe' }
        
        if ($PowerShellProfile) {
            $PowerShellProfile.fontFace = $FontName
        }
        
        $SettingsContent | ConvertTo-Json -Depth 10 | Set-Content $File.FullName -Force -Encoding UTF8
        Write-Host "✅ Fonte do Windows Terminal configurada para '$FontName'." -ForegroundColor Green
    } catch {
        Write-Warning "❌ Falha ao modificar o settings.json. Configure manualmente se o Windows Terminal parecer estranho."
    }
}

function Set-TerminalFont {
    param(
        [string]$FontName = "Hack Nerd Font"
    )

    Write-Host "`n-> Tentando configurar '$FontName' no Windows Terminal..." -ForegroundColor Yellow

    # Caminho padrão do arquivo settings.json do Windows Terminal
    $SettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json"
    
    # Encontra o caminho real, que pode variar pelo ID do pacote
    $File = Get-ChildItem -Path $SettingsPath -ErrorAction SilentlyContinue

    if (-not $File) {
        Write-Warning "❌ Arquivo de configurações do Windows Terminal não encontrado. Pule a configuração automática."
        return
    }

    try {
        # Lê e parseia o JSON
        $SettingsContent = Get-Content $File.FullName | Out-String | ConvertFrom-Json -ErrorAction Stop
        
        # Tenta definir a fonte padrão
        if ($SettingsContent.profiles.defaults) {
            $SettingsContent.profiles.defaults.fontFace = $FontName
        }

        # Tenta definir a fonte para o perfil do PowerShell especificamente
        $PowerShellProfile = $SettingsContent.profiles.list | Where-Object { $_.commandline -like '*powershell.exe' }
        
        if ($PowerShellProfile) {
            $PowerShellProfile.fontFace = $FontName
        }
        
        # Converte de volta para JSON e salva
        $SettingsContent | ConvertTo-Json -Depth 10 | Set-Content $File.FullName -Force -Encoding UTF8
        Write-Host "✅ Fonte do Windows Terminal configurada para '$FontName'." -ForegroundColor Green
    } catch {
        Write-Warning "❌ Falha ao modificar o settings.json. Configure manualmente se o Windows Terminal parecer estranho."
    }
}

# Garante que o script está rodando como Administrador
Get-AdminPermission

# INSTALAÇÃO E CONFIGURAÇÃO DA FONTE PARA RESOLVER ACENTOS
Install-NerdFont
Set-TerminalFont

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
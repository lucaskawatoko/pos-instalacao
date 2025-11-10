# ----------------------------------------------------------------------
# Script de Pós-Instalação e Setup DEV com Nível Máximo de Trollagem
# (Versão Final: Áudio, Notepad e Bloqueio de Tela Forçado)
# ----------------------------------------------------------------------

# --- CORREÇÃO DE CODIFICAÇÃO ROBUSTA (PARA ACENTOS) ---

chcp 65001 | Out-Null
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# --- PARTE 0: Funções e Segurança ---

function Get-AdminPermission {
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
    
    Write-Host "-> Verificando $Name..." -NoNewline
    $Check = winget list --id "$ID"
    if ($Check -match "$ID") {
        Write-Host " Já instalado. Pulando." -ForegroundColor DarkYellow
        return
    }

    Write-Host " Não instalado. Iniciando $Name (ID: $ID)..." -ForegroundColor Yellow
    $command = "winget install --id=$ID -e --accept-package-agreements --silent"
    
    try {
        & cmd /c $command 
        Write-Host "✅ $Name instalado com sucesso." -ForegroundColor Green
    } catch {
        Write-Warning "❌ Falha ao instalar $Name. Verifique a instalação do winget."
    }
}

function Set-TerminalFont {
    param(
        [string]$FontName = "HackNerdFont" 
    )

    Write-Host "`n-> Tentando configurar '$FontName' no Windows Terminal..." -ForegroundColor Yellow

    $SettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json"
    $File = Get-ChildItem -Path $SettingsPath -ErrorAction SilentlyContinue

    if (-not $File) {
        Write-Warning "❌ Arquivo de configurações do Windows Terminal não encontrado."
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
        Write-Warning "❌ Falha ao modificar o settings.json. Configure manualmente se necessário."
    }
}

function Install-NerdFont {
    Write-Host "`n--- INSTALAÇÃO DE FONTE PARA ACENTOS ---" -ForegroundColor Cyan
    Write-Host "-> Verificando se a Hack Nerd Font já está instalada..." -ForegroundColor Yellow
    
    $FontNameCheck = "*HackNerdFont-Regular*"
    $FontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    
    if (Get-ItemProperty -Path $FontRegistryPath -ErrorAction SilentlyContinue | Where-Object { $_.PSObject.Properties.Name -like $FontNameCheck }) {
        Write-Host "✅ Hack Nerd Font já instalada. Pulando download." -ForegroundColor DarkYellow
        Set-TerminalFont -FontName "HackNerdFont"
        return
    }

    Write-Host "-> Iniciando download e instalação da fonte..." -ForegroundColor Yellow
    
    $ZipUrl = "https://raw.githubusercontent.com/lucaskawatoko/pos-instalacao/main/Hack.zip"
    $TempDir = Join-Path $env:TEMP "HackFontInstall"
    $ZipFile = Join-Path $TempDir "Hack.zip"
    $FontDir = Join-Path $TempDir "Fonts"

    if (-not (Test-Path $TempDir)) { New-Item -Path $TempDir -ItemType Directory -Force | Out-Null }
    
    try {
        Write-Host "   - Baixando Hack.zip..." -NoNewline
        Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile -ErrorAction Stop
        Write-Host " OK." -ForegroundColor Green
    } catch {
        Write-Warning "❌ Falha ao baixar o arquivo ZIP da fonte."
        Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        return
    }

    try {
        Write-Host "   - Descompactando..." -NoNewline
        if (-not (Test-Path $FontDir)) { New-Item -Path $FontDir -ItemType Directory -Force | Out-Null }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $FontDir)
        Write-Host " OK." -ForegroundColor Green
    } catch {
        Write-Warning "❌ Falha ao descompactar o arquivo ZIP."
        Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        return
    }

    Write-Host "   - Instalando fontes no sistema..." -NoNewline
    $FontInstaller = New-Object -ComObject Shell.Application
    $FontFolder = $FontInstaller.Namespace(0x14) 
    
    Get-ChildItem -Path $FontDir -Filter "*.ttf" | ForEach-Object {
        try {
            $FontFolder.CopyHere($_.FullName, 0x04) | Out-Null
        } catch {
            Write-Warning "   - Falha ao instalar a fonte $($_.Name)."
        }
    }
    Write-Host " OK." -ForegroundColor Green

    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "✅ Hack Nerd Font instalada com sucesso!" -ForegroundColor Green
    
    Set-TerminalFont -FontName "HackNerdFont"
}

function Play-ScareSound {
    param(
        [string]$Mp3Url = "https://raw.githubusercontent.com/lucaskawatoko/pos-instalacao/main/scream-of-terror-325532.mp3"
    )
    
    $TempPath = Join-Path $env:TEMP "scream_troll.mp3"
    
    try {
        Invoke-WebRequest -Uri $Mp3Url -OutFile $TempPath -ErrorAction Stop -UseBasicParsing | Out-Null
    } catch {
        return
    }

    try {
        Start-Process $TempPath | Out-Null
        Start-Sleep -Seconds 4 
    } catch {
    }
}


# Garante que o script está rodando como Administrador
Get-AdminPermission

# --- PARTE 1: Configuração Inicial e Fonte (Opcional) ---

Write-Host "`n--- 1. Configuração Inicial e Fonte ---" -ForegroundColor Cyan

$fontChoice = Read-Host "Deseja instalar a Hack Nerd Font para melhor visualização de acentos e ícones? [S/N]"

if ($fontChoice -ceq 's') {
    Install-NerdFont
} else {
    Write-Host "Instalação da fonte pulada." -ForegroundColor Yellow
}

# --- PARTE 2: Atualizações Essenciais ---

Write-Host "`n--- 2. Atualizações de Componentes ---" -ForegroundColor Cyan

Install-Winget -ID "Microsoft.PowerShell" -Name "PowerShell 7 (Novo)"

# --- PARTE 3: Escolha e Instalação de Navegador ---

Write-Host "`n--- 3. Seleção de Navegador Web ---" -ForegroundColor Cyan

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

# --- PARTE 4: Pacote DEV e Ferramentas (Opcional) ---

Write-Host "`n--- 4. Pacote de Desenvolvimento e Ferramentas ---" -ForegroundColor Cyan

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


# --- PARTE 5: Configuração WSL2 e Distros (Interativo) ---

Write-Host "`n--- 5. Subsistema Windows para Linux (WSL) ---" -ForegroundColor Cyan

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


# --- PARTE 6: A Trollagem Final (Furtiva) ---

# 1. Toca o som de terror em background
Play-ScareSound

# 2. Define Papel de Parede (Silenciosamente)
$Url = "https://images.hdqwalls.com/wallpapers/v-for-vendetta-remember-the-fifth-of-december-ef.jpg"
$outDir = Join-Path $env:USERPROFILE "Pictures"
$outFile = Join-Path $outDir "wallpaper.jpg"

if (-not (Test-Path -Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }

try {
    Invoke-WebRequest -Uri $Url -OutFile $outFile -UseBasicParsing | Out-Null
} catch {}

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


# 3. Abre o Bloco de Notas com a Mensagem de Aviso
$NotepadFile = Join-Path $env:USERPROFILE "Desktop\AVISO_DE_SEGURANCA.txt"
$Message = "NUNCA MAIS BAIXE NADA SEM SABER!"

$Message | Out-File $NotepadFile -Encoding UTF8

Start-Process notepad.exe -ArgumentList $NotepadFile | Out-Null

Start-Sleep -Seconds 1 

# 4. EFEITO DE TERROR: BLOQUEIO DE TELA
# Usa Start-Process para garantir que o rundll32 seja executado como um novo processo,
# garantindo que o bloqueio ocorra.
Start-Process -FilePath "rundll32.exe" -ArgumentList "user32.dll,LockWorkStation" -Wait -WindowStyle Hidden

# O script termina aqui, pois a tela está bloqueada.
# ----------------------------------------------------------------------
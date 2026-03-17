<#
.SYNOPSIS
    Skript pro zrcadlení složek v reálném čase s GUI výběrem.
    
.DESCRIPTION
    Tento skript monitoruje zdrojovou složku a při jakékoli změně (vytvoření, úprava, smazání) 
    provede zrcadlení do cílové složky pomocí nástroje Robocopy.
    Podporuje lokální i UNC cesty.
#>

Add-Type -AssemblyName System.Windows.Forms

# --- OPRAVA KÓDOVÁNÍ A ADMIN PRÁVA ---
# Vynucení UTF-8 pro konzoli hned na začátku
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$OutputEncoding = [System.Text.Encoding]::UTF8

# Kontrola a vynucení Administrátora
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
# -------------------------------------

# Pomocná funkce pro češtinu (řeší problémy s kódováním souboru)
function cz($text) {
    return $text -replace 'zrcadleni', "zrcadlen$([char]237)" `
                -replace 'spusteno', "spu$([char]353)t$([char]283)no" `
                -replace 'Zdroj', "Zdroj" `
                -replace 'Cil', "C$([char]237)l" `
                -replace 'Stisknete', "Stiskn$([char]283)te" `
                -replace 'ukonceni', "ukon$([char]269)en$([char]237)" `
                -replace 'Detekovana zmna', "Detekov$([char]225)na zm$([char]283)na" `
                -replace 'synchronizuji', "synchronizuji" `
                -replace 'Vyberte ZDROJOVOU slozku', "Vyberte ZDROJOVOU slo$([char]382)ku" `
                -replace 'hlidat', "hl$([char]237)dat" `
                -replace 'Vyberte CILOVOU slozku', "Vyberte C$([char]237)LOVOU slo$([char]382)ku" `
                -replace 'zrcadlit', "zrcadlit" `
                -replace 'Konfigurace nenalezena', "Konfigurace nenalezena" `
                -replace 'Hotovo', "Hotovo"
}

$ConfigFile = Join-Path $PSScriptRoot "mirror_config.json"

function Get-Folder($Title) {
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.Description = $Title
    $FolderBrowser.ShowNewFolderButton = $true
    if ($FolderBrowser.ShowDialog() -eq "OK") {
        return $FolderBrowser.SelectedPath
    }
    return $null
}

# Načtení nebo vytvoření konfigurace
if (Test-Path $ConfigFile) {
    $Config = Get-Content $ConfigFile | ConvertFrom-Json
    $SourcePath = $Config.SourcePath
    $DestinationPath = $Config.DestinationPath
} else {
    Write-Host (cz "Konfigurace nenalezena, spouštím výběr složek...") -ForegroundColor Cyan
    $SourcePath = Get-Folder (cz "Vyberte ZDROJOVOU slozku (tu, kterou chcete hlidat)")
    if (-not $SourcePath) { exit }
    
    $DestinationPath = Get-Folder (cz "Vyberte CILOVOU slozku (kam se má zrcadlit)")
    if (-not $DestinationPath) { exit }
    
    $Config = @{
        SourcePath = $SourcePath
        DestinationPath = $DestinationPath
    }
    $Config | ConvertTo-Json | Set-Content $ConfigFile
}

Write-Host (cz "zrcadleni spusteno:") -ForegroundColor Green
Write-Host "Zdroj: $SourcePath"
Write-Host (cz "Cil:   $DestinationPath")
Write-Host (cz "Stisknete Ctrl+C pro ukonceni.")

# Funkce pro samotné zrcadlení
$SyncAction = {
    param($Source, $Dest)
    Write-Host ("$(Get-Date -Format 'HH:mm:ss') - " + (cz "Detekovana zmna, synchronizuji...")) -ForegroundColor Yellow
    # Odstraněny potlačující parametry (/NP /NFL /NDL /NJH /NJS), aby byl vidět průběh
    robocopy $Source $Dest /MIR /R:2 /W:5 /MT:8
    Write-Host (cz "Hotovo.") -ForegroundColor Gray
}

# Inicializace FileSystemWatcher
$Watcher = New-Object System.IO.FileSystemWatcher
$Watcher.Path = $SourcePath
$Watcher.IncludeSubdirectories = $true
$Watcher.EnableRaisingEvents = $true

# Registrace událostí
$Handlers = @()
$Events = "Created", "Changed", "Deleted", "Renamed"

foreach ($Ev in $Events) {
    $Handlers += Register-ObjectEvent $Watcher $Ev -Action {
        if (-not $global:IsSyncing) {
            $global:IsSyncing = $true
            Start-Sleep -Seconds 2
            & $Event.MessageData $SourcePath $DestinationPath
            $global:IsSyncing = $false
        }
    } -MessageData $SyncAction
}

# Prvotní synchronizace při startu
& $SyncAction $SourcePath $DestinationPath

# Smyčka pro udržení skriptu v běhu
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
finally {
    # Úklid při ukončení
    foreach ($Handler in $Handlers) {
        Unregister-Event -SourceIdentifier $Handler.Name
    }
    $Watcher.Dispose()
}

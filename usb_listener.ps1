# Script de surveillance USB pour périphériques Samsung
# Nécessite des privilèges administrateur

param(
    [string]$ScriptPath = "gni"
)

# Vérification des privilèges administrateur
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Ce script nécessite des privilèges administrateur." -ForegroundColor Red
    Write-Host "Veuillez exécuter PowerShell en tant qu'administrateur." -ForegroundColor Yellow
    exit 1
}

# Vérification de l'existence du script batch


Write-Host "=== Surveillance USB Samsung ===" -ForegroundColor Cyan
Write-Host "Script à exécuter: $ScriptPath" -ForegroundColor Green
Write-Host "Démarrage de la surveillance..." -ForegroundColor Green

# Définir l'encodage de sortie pour corriger les caractèresw
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Requête WMI pour détecter les périphériques Samsung
$query = @"
SELECT * FROM __InstanceCreationEvent WITHIN 2 
WHERE TargetInstance ISA 'Win32_PnPEntity' 
AND (TargetInstance.Description LIKE '%Samsung%' 
    OR TargetInstance.Name LIKE '%Samsung%'
    OR TargetInstance.DeviceID LIKE '%SAMSUNG%')
"@

try {
    # Enregistrement de l'observateur d'événements
    $eventJob = Register-WmiEvent -Query $query -Action {
        $deviceName = $Event.SourceEventArgs.NewEvent.TargetInstance.Name
        $deviceDescription = $Event.SourceEventArgs.NewEvent.TargetInstance.Description
        
        Write-Host "`n[$([datetime]::Now.ToString('HH:mm:ss'))] Périphérique Samsung détecté!" -ForegroundColor Green
        Write-Host "Nom: $deviceName" -ForegroundColor Yellow
        Write-Host "Description: $deviceDescription" -ForegroundColor Yellow
        Write-Host "Exécution du script batch..." -ForegroundColor Green
        
        try {
            # Exécuter le script batch directement
            $batchResult = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$ScriptPath`""
            
            if ($batchResult.ExitCode -eq 0) {
                Write-Host "Script exécuté avec succès." -ForegroundColor Green
            } else {
                Write-Host "Script terminé avec le code d'erreur: $($batchResult.ExitCode)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "ERREUR lors de l'exécution du script: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "Surveillance active. Appuyez sur Ctrl+C pour arrêter." -ForegroundColor Cyan
    Write-Host "En attente de connexion d'un périphérique Samsung..." -ForegroundColor Gray
    
    # Boucle d'attente
    while ($true) {
        Start-Sleep -Seconds 10
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
}
catch {
    Write-Host "ERREUR: Impossible de démarrer la surveillance: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # Nettoyage à l'arrêt
    if ($eventJob) {
        Get-EventSubscriber | Unregister-Event
        Write-Host "`nSurveillance arrêtée." -ForegroundColor Yellow
    }
}
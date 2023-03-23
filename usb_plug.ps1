#Requires -version 2.0
# il faut etre admin why 
# schtasks /create /sc hourly /mo 1 /tn "MYTASK02" /tr "C:\test\test.bat" /st 00:00 /ru system /rl highest
# /tn "MYTASK02"
# schtasks /query /tn "MYTASK02"
# schtasks /delete /tn "MYTASK02"
# TODO : trace via log - EC
# TODO : paramtrage via fichier INI EC
# TEST : cas ou le lecteur est deja monté
# TODO : Bitlocker https://serverfault.com/questions/1033703/how-to-add-credentials-to-bitlocker-script
# BUG : dans certain cas le label est mal récupéré
# TODO : prévoir un chargement à la volée du fichier .ini (base sur la date modification du fichier)
# TODO : avoir un fichier par jour et as par heure

# Source : https://www.developpez.net/forums/d1612364/general-developpement/programmation-systeme/windows/scripts-batch/modifier-fichier-configuration/
# fonction de lecture d'un fichier ini
# Paraemter : file ini to be analyse
#-------------------------------------------------------------------------------
function Get-IniContent ($filePath)
{
    switch -regex -file $filePath
    {
        "^\[(.+)\]$"
        {
            $section = $matches[1]
        }
        "(.+)=(.*)"
        {
            $name, $value = $matches[1..2]
            New-Object -TypeName PSObject -Property @{Section = $section
                                    Parametre = $name
                                    Valeur = $value
                                    } | Select-Object Section, Parametre, Valeur
        }
    }
}

# Source : https://blog.piservices.fr/post/2021/10/30/powershell-creer-une-fonction-de-logging
# Fonction qui permet de récupérer la ligne actuelle dans un script, 
# elle sera utilisée par le script qui appelle la fonction de log
# Parameter : N/A
function Get-CurrentLineNumber 
{
    Return $MyInvocation.ScriptLineNumber
}
#
# #Fonction qu'il faudra appeler lorsque l'on voudra faire du logging
function Write-Log 
{
    [CmdletBinding()] #Déclaration des paramètres qu'il faudra fournir à la fonction pour qu'elle puisse s'exécuter
    param
    (
        [Parameter(Mandatory=$true)] #Indique que ce paramètre est obligatoire
        [ValidateNotNullOrEmpty()] #Indique que ce champ ne peut pas être vide ou null
        [string]$LogFile, #Paramètre qui contient le chemin complet du script qui appelle la fonction de log
 
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogLine, #Paramètre qui contient la ligne à laquelle la fonction de log est appelée
 
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogMessage, #Paramètre qui contient le log
 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$LogPath, #Paramètre qui contient le chemin complet du fichier de log
  
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')] #Valeurs disponibles pour qualifier le log
        [string]$LogSeverity #Paramètre qui va quantifier la nature du log parmi les valeurs disponibles
    )
 
    Begin
    {
        if (!$LogPath) #Code qui permet de générer un dossier de log ainsi que le fichier de log de façon dynamique si le paramètre LogPath est vide
        {
            # $CurrentDateFormatForLog = Get-Date -Format "yyyy-MM-dd_HH" #Recupère la date du jour pour la mettre à la fin du nom de fichier de log
            $CurrentDateFormatForLog = Get-Date -Format "yyyy-MM-dd" #Recupère la date du jour pour la mettre à la fin du nom de fichier de log
            $LogFolderName = "Logs" #Nom du fichier de log
            $LogFolderPath = $PSScriptRoot + "\" + $LogFolderName #Détermine dynamiquement la localisation du dossier de log qui doit se trouver dans le même dossier que le script PowerShell qui appelle la fonction de log
             
            if (!(Test-Path -Path $LogFolderPath))#Vérifie l'existence d'un dossier de log dans le même dossier que le script qui appelle la fonction de log
            {
                New-Item -ItemType Directory -Path $LogFolderPath | Out-Null #Si le dossier de log n'existe pas, le créé
            }
             
            $LogPath = $LogFolderPath + "\" + "Log_" + $CurrentDateFormatForLog + ".csv" #Détermine le nom du chemin complet du fichier de log
        }
    }
     
    Process
    {
        [pscustomobject]@{ #Génére un objet PowerShell dont chaque ligne représente une colonne du fichier de log
            Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss" #Première colonne qui contient la date à laquelle la fonction de log s'est exécuté
            Severity = $LogSeverity #Deuxième colonne qui contient la nature du log
            File = $LogFile #Troisième colonne qui contient le nom du script PowerShell qui appelle la fonction de log
            Line = $LogLine #Quatrième colonne qui contient la ligne à laquelle la fonction de log a été appelée
            Message = $LogMessage #Cinquième colonne qui contient le log
             
        } | Export-Csv -Path $LogPath -Append -NoTypeInformation -Delimiter ";" -Encoding UTF8 #Code qui permet de transformer l'objet PowerShell en fichier de log (csv)
    }
}
# main 
# ======================================================================
write-host (get-date -format s) " Beginning script..."
Write-Log -LogSeverity "Information" -LogMessage " Beginning script..." -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
write-host "-------------------------------------------------------"
$Message=" Script Name " + $PSCommandPath
#Write-Log -LogSeverity "Information" -LogMessage " Script Name "$PSCommandPath -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
Write-Log -LogSeverity "Information" -LogMessage " Script Name " -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
Write-Log -LogSeverity "Information" -LogMessage $Message -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
write-host " Execution directory  : "$PSScriptRoot
$Message=" Execution directory " + $PSScriptRoot
Write-Log -LogSeverity "Information" -LogMessage  $Message -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
write-host "-------------------------------------------------------"
# Menage dans les log (fonction à faire)
# $PSScriptRoot\log 
# $IniContent | Where-Object { $_.Section -match "^$driveLabel$"} |  Where-Object { $_.Parametre -match "^Letter$"}
write-host "Purge automatique"
$LogFolderName=$PSScriptRoot+"\Logs"
write-host $DirTra
$ListFile = Get-ChildItem $LogFolderName -Recurse -File | Where-Object CreationTime -lt  (Get-Date).AddDays(-1)  # | Remove-Item -Force -Recurse
write-host $ListFile
Register-WmiEvent -Class win32_VolumeChangeEvent -SourceIdentifier volumeChange
write-host "-------------------------------------------------------"
#
#Lecture du fichier ini
# -------------------------------------------------------------------------------
$FileIni="$PSScriptRoot\USB2Letter.ini"
# $Fichiers = Get-ChildItem $sourcebak
$IniContent = Get-IniContent $FileIni
$DateFileIni = (Get-ChildItem $FileIni).LastWriteTime
$Message="Date : "+$DateFileIni
Write-Log -LogSeverity "Information" -LogMessage $Message -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
#
# Context information 
# -------------------------------------------------------------------------------
# $FileIni= "File Ini : $PSScriptRoot\USB2Letter.ini"
Write-Log -LogSeverity "Information" -LogMessage $FileIni -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
write-host (Get-ExecutionPolicy)
$Message= (Get-ExecutionPolicy)
Write-Log -LogSeverity "Information" -LogMessage $Message -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
# 


do{
    $newEvent = Wait-Event -SourceIdentifier volumeChange
    $eventType = $newEvent.SourceEventArgs.NewEvent.EventType
    $eventTypeName = switch($eventType)
    {
        1 {"Configuration changed"}
        2 {"Device arrival"}
        3 {"Device removal"}
        4 {"docking"}
    }
    write-host (get-date -format s) " Event detected = " $eventTypeName
    if ($eventType -eq 2)
    {
        Write-Log -LogSeverity "Information" -LogMessage  "Rechargement ?" -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
        if ((Get-ChildItem $FileIni).LastWriteTime -ge $DateFileIni)
        {
            $IniContent = Get-IniContent $FileIni
            $DateFileIni = (Get-ChildItem $FileIni).LastWriteTime     
            #trace 
            $Message='Le fichier'+ $FileIni + 'a été rechargé'
            Write-Host $Message
            Write-Log -LogSeverity "Information" -LogMessage  $Message -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
        }
        $driveLetter = $newEvent.SourceEventArgs.NewEvent.DriveName
        $Message = " Drive name = " + $driveLetter
        Write-Log -LogSeverity "Information" -LogMessage  $Message -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
        start-sleep -seconds 1
        # Recherche des informations sur le device USB
        write-host (get-date -format s) "Recherche des informations sur le device USB"
        $driveLabel = ([wmi]"Win32_LogicalDisk='$driveLetter'").VolumeName
        $Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$driveLetter'"
        write-host (get-date -format s) $Drive
        $Drive | Select-Object -Property SystemName, Label, DriveLetter
        write-host (get-date -format s) $Drive.Label 
        write-host (get-date -format s) $Drive.DriveLetter
        $driveLabel=$Drive.Label
        write-host (get-date -format s) $Drive.Label
        write-host (get-date -format s) " Drive name = " $driveLetter
        write-host (get-date -format s) " Drive label = " $driveLabel
        $Message = " Drive name = " + $driveLetter + " Drive label = " + $driveLabel
        Write-Log -LogSeverity "Information" -LogMessage  $Message -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
        # Execute process if drive matches specified condition(s)
        # if ($driveLetter -eq 'Z:' -and $driveLabel -eq 'Mirror')
        if (-not $driveLabel)
        {
            write-host (get-date -format s) " Pas de Drive label = " $driveLabel
            write-host (get-date -format s) "[$driveletter]"
            $disk = Get-WmiObject -Class win32_volume -Filter "DriveLetter = '$driveletter'"
            write-host (get-date -format s) $disk
        }
        $Letter=$IniContent | Where-Object { $_.Section -match "^$driveLabel$"} |  Where-Object { $_.Parametre -match "^Letter$"}
        $Action=$IniContent | Where-Object { $_.Section -match "^$driveLabel$"} |  Where-Object { $_.Parametre -match "^Action$"} 


        # if ($driveLabel -eq 'TOOLC128GO')
        # {
        write-host (get-date -format s) " Starting task in 1 seconds..."
        Write-Log -LogSeverity "Information" -LogMessage  " Starting task in 1 seconds..." -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
        start-sleep -seconds 1

        # if ($driveLetter -ne 'S:')
        if ($driveLetter -ne $Letter.Valeur)
        {
            # Changement de lecteur 
            $Message = "Changement de lecteur pour "+ $driveLabel +" de "+ $driveLetter +"avec " +$Letter.Valeur
            Write-Host (get-date -format s) "Changement de lecteur "$driveLabel $Letter.Valeur
            Write-Log -LogSeverity "Information" -LogMessage  $Message -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
            #try {
            Get-BitLockerVolume -MountPoint "E:"
            #Get-CimInstance -Query "SELECT * FROM Win32_Volume WHERE Label='$driveLabel'" | Set-CimInstance -Arguments @{DriveLetter=$Letter.Valeur}
            $A=Get-CimInstance -Query "SELECT * FROM Win32_Volume WHERE Label='$driveLabel'"  
            try {
                Set-CimInstance -InputObject $A -Arguments @{DriveLetter=$Letter.Valeur}
                $Message = "Changement de lecteur pour "+ $A + "execute. Nouvelle "+ $Letter.Valeur
                Write-Log -LogSeverity "Information" -LogMessage  $Message -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
            }
            catch {
                Write-Log -LogSeverity "Error" -LogMessage $_.Exception.Message -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
            }
           
            #    Write-Log -LogSeverity "Information" -LogMessage  "TOTO" -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
            #}
            #catch {
            #    <#Do this if a terminating exception happens#>
            #    
            # }

            # Get-CimInstance -Query "SELECT * FROM Win32_Volume WHERE Label='$driveLabel'" | Set-CimInstance -Arguments @{DriveLetter="S:"}
            #Get-Partition -DriveLetter $driveLetter | Set-Partition -NewDriveLetter "S:"
        }
        else 
        {
            write-host (get-date -format s) "Pas de  changement!"
            Write-Log -LogSeverity "Information" -LogMessage $_.Exception.Message -LogFile $PSCommandPath -LogLine $(Get-CurrentLineNumber)
        }
        # start-process (-join($driveLetter, "\sync.bat")) 
        # }
        write-host $Action
    }
    Remove-Event -SourceIdentifier volumeChange
} while (1-eq1) #Loop until next event
Unregister-Event -SourceIdentifier volumeChange
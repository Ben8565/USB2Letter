#Requires -version 2.0
# il faut etre admin why 
# schtasks /create /sc hourly /mo 1 /tn "MYTASK02" /tr "C:\test\test.bat" /st 00:00 /ru system /rl highest
# /tn "MYTASK02"
# schtasks /query /tn "MYTASK02"
# schtasks /delete /tn "MYTASK02"
# TODO : trace via log
# TODO : parametrage via fichier INI
# TEST : cas ou le lecteur est deja monté

# https://www.developpez.net/forums/d1612364/general-developpement/programmation-systeme/windows/scripts-batch/modifier-fichier-configuration/
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
                                    } | Select Section, Parametre, Valeur
        }
    }
}

# $IniContent = Get-IniContent "sip.conf"
# $IniContent | where { $_.Section -match "^[0-9]{4}$"} | sort-object section, parametre


Register-WmiEvent -Class win32_VolumeChangeEvent -SourceIdentifier volumeChange
write-host (get-date -format s) " Beginning script..."
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
        $driveLetter = $newEvent.SourceEventArgs.NewEvent.DriveName
        write-host (get-date -format s) " Drive name = " $driveLetter
        start-sleep -seconds 1
        $driveLabel = ([wmi]"Win32_LogicalDisk='$driveLetter'").VolumeName
        write-host (get-date -format s) " Drive name = " $driveLetter
        write-host (get-date -format s) " Drive label = " $driveLabel
        # Execute process if drive matches specified condition(s)
        # if ($driveLetter -eq 'Z:' -and $driveLabel -eq 'Mirror')
        if ($driveLabel -eq 'TOOLC128GO')
        {
        write-host (get-date -format s) " Starting task in 1 seconds..."
        start-sleep -seconds 1
        # $driveLetter 
        # Write-Host (-join($driveLetter, "\sync.bat")) 
        #start-sleep -seconds 2
        if ($driveLetter -ne 'S:')
        {
            # Changement de lecteur 
            Write-Host (get-date -format s) "Changement de lecteur"
            Get-CimInstance -Query "SELECT * FROM Win32_Volume WHERE Label='TOOLC128GO'" | Set-CimInstance -Arguments @{DriveLetter="S:"}
            # Get-CimInstance -Query "SELECT * FROM Win32_Volume WHERE Label='$driveLabel'" | Set-CimInstance -Arguments @{DriveLetter="S:"}
            #Get-Partition -DriveLetter $driveLetter | Set-Partition -NewDriveLetter "S:"
        }
        else 
        {
            write-host (get-date -format s) "Pas de  changement!"
        }
        # start-process (-join($driveLetter, "\sync.bat")) 
        }
    }
    Remove-Event -SourceIdentifier volumeChange
} while (1-eq1) #Loop until next event
Unregister-Event -SourceIdentifier volumeChange
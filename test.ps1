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
$driveLabel = "EMTEC B111"
$IniContent = Get-IniContent "USB2Letter.ini"
#$Letter=$IniContent | Where { $_.Section -match "^$driveLabel$"} |  Where { $_.Parametre -match "^Letter$"} |sort-object section, parametre
$Letter=$IniContent | Where-Object { $_.Section -match "^$driveLabel$"} |  Where-Object { $_.Parametre -match "^Letter$"}
$Action=$IniContent | Where { $_.Section -match "^$driveLabel$"} |  Where { $_.Parametre -match "^Action$"} |sort-object section, parametre


[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	
# $oReturn=[System.Windows.Forms.Messagebox]::Show($Letter.Valeur)
[System.Windows.Forms.Messagebox]::Show($Letter.Valeur)
# $oReturn=[System.Windows.Forms.Messagebox]::Show($Action.Valeur)
[System.Windows.Forms.Messagebox]::Show($Action.Valeur)
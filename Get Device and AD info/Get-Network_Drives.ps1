Clear

$TargetName = Read-Host "Enter the target PC number (or Name)"

$arrDrives = Get-WmiObject Win32_MappedLogicalDisk -computer $TargetName
$arrResult = @()
Foreach($x in $arrDrives)
{
    $objDrive = [PSCustomObject]@{MappedDriveLetter=$null; Path=$null}

    $objDrive.MappedDriveLetter = $x.name
    $objDrive.Path = $x.providername

    $arrResult += ($objDrive)
}

Foreach($a in $arrResult) 
{
    Write-Host($a.MappedDriveLetter +" "+ $a.Path)
}
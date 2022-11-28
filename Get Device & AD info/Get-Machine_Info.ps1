Clear

$TargetName = Read-Host "Enter the target PC number (or Name)"

    $arrActiveUsers = @()
    foreach($ServerLine in @(query user /server:$TargetName) -split "\n")
    {
        $objUserData = [PSCustomObject]@{Username=$null;SessionState=$null;LogonTime=$null}

        $Parsed_Server = $ServerLine -split '\s+'

        $objUserData.Username = $Parsed_Server[1] #USERNAME
        $objUserData.SessionState = $Parsed_Server[4] #STATE
        $objUserData.LogonTime = $Parsed_Server[6] + ' - ' + $Parsed_Server[7] #LOGON TIME [dd/MM/yyyy - hh:mm]

        $arrActiveUsers += ($objUserData | where SessionState -Like 'Active')
    }
$objDetails = New-Object -TypeName PSObject -Property @{
    'Computer Name' = (Get-ADComputer -Identity $TargetName -Properties *).Name
    'Serial Number / Service tag' = (Get-WmiObject -classname win32_bios -computername $TargetName -Property SerialNumber).SerialNumber
    'AD Description' = (Get-ADComputer -Identity $TargetName -Properties *).Description
    'IPv4 Address' = (Get-ADComputer -Identity $TargetName -Properties *).IPv4Address
    'Operating System' = ((Get-WmiObject -Class Win32_OperatingSystem -Computer $TargetName).Caption + ' ' + (Get-WmiObject -Class Win32_OperatingSystem -Computer $TargetName).Version)
    'Active Users' = ($arrActiveUsers |ForEach-Object {"User: {0} `r`nLogged on: {1}`r`nCurrent session state: {2}`r`n" -f $_.Username, $_.LogonTime, $_.SessionState})
}
Write-Output $objDetails | SELECT 'Computer Name','Serial Number / Service tag','AD Description','IPv4 Address','Operating System','AD Distinguished Name'
Write-Output $objDetails | ForEach-Object -MemberName 'Active Users'

Read-Host -Prompt "Press enter key to exit."
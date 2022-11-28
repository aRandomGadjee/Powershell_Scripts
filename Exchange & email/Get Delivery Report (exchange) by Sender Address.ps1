Clear

$daysInt = $null

while($daysInt -eq $null){
    $senderAddress = Read-Host("Enter the Sender Email Address ")
    $numberOfDays = Read-Host("Enter number of days you want to see (eg. 30) ")
    $daysInt = $numberOfDays -as [int]
    $now = Get-Date
    $outputPath = "C:\MessageTrackingLog_("+$now.Date.ToString("dd-MM-yyyy")+").csv"

    if($daysInt -eq $null){Write-Host("Please provide the 'days' argument as a whole number. '"+$numberOfDays+"' is not a number!")}
}

Get-MessageTrackingLog -EVENTID DELIVER -Sender $senderAddress -Start $now.AddDays(-$daysInt) -End $now -ResultSize unlimited|select timestamp, sender, @{n="Recipients"; e={$_.Recipients}}, Messagesubject | Export-Csv -NoTypeInformation $outputPath

Write-Host("Tracking data output to: " + $outputPath)
###
# This works best when ran from the Windows Terminal, as powershell :)
###
clear
Function JobStarter($job)
{
    #### This is the spinner block code
    $symbols = "⣾⣽⣻⢿⡿⣟⣯⣷⣿"
    $pos = $host.UI.RawUI.CursorPosition
    $pos.Y += 1
    $i = 0;
    while ($job.State -eq "Running") 
    {
        $host.UI.RawUI.CursorPosition = $pos
        Write-Host $symbols[$i] -NoNewline
        $i++
        if ($i -ge $symbols.Length){$i = 0}
        Start-Sleep -Milliseconds 50
    }
    $host.UI.RawUI.CursorPosition = $pos
    Write-Host " " #clears spinner
    #### End of the spinner block code

    if($job.State -eq "Completed"){JobCompleted($job)}
    if($job.State -eq "Failed"){JobFailed($job)}

    ShowCurrentJobs
    CleanUpJob($job)
    ShowCurrentJobs
}

## Completion Functions
Function JobFailed($job){
    Write-Host "Job:"($job.Name)"Has Failed!" -ForegroundColor Red
    Receive-Job $job
}
Function JobCompleted($job){
    #Get Results
    Write-Host "Job:"($job.Name)"Completed!" -ForegroundColor Green
    Write-Host "Results: "
    Receive-Job $job
}

Function CleanUpJob($job){
    $ans
    Do
    {
        Write-Host "Do you want to delete the job"($job.Name)"?"
        Write-Host "(Y or N)"
        $ans = Read-Host
    } While($ans -notmatch "y|n")
    if($ans -ceq "n") {return}
    Remove-Job -Id $job.Id
    Write-Host "Job"($job.Name)"Is deleted!" -ForegroundColor Green
}

Function ShowCurrentJobs(){
    Write-Host ""
    Write-Host "Current Jobs:"
    $jobsList = $null
    $jobsList = Get-Job | SELECT Id, Name, State, PSBeginTime, PSEndTime, Command | Format-Table -AutoSize
    if($jobsList -eq $null){
        Write-Host "No Jobs exist!"
        return
    }
    $jobsList | Out-String |% {Write-Host $_}
}

# Declare functions for initialisation scrips
$Functions = {
    ## Work Functions
    Function PingPC([string]$pcname){Test-Connection -ComputerName $pcname}
}

# Assign the job
$job1 = Start-Job -InitializationScript $Functions -ScriptBlock {PingPC("pc40930")}

#Start the job uing the job starter function
JobStarter($job1)
$arrUserObjects = @()
$Rundate = Get-Date -Format "dd-MM-yyyy"
$DocumentsPath = [Environment]::GetFolderPath("MyDocuments")
$path = $DocumentsPath + "\Company Car Drivers " + $Rundate + ".csv"

$GroupName = Read-Host -Prompt "Please enter the group you wish to query: (wrap it in 'single quotes' :))"

$GroupName = $GroupName.Replace("'","")

TRY {
    $CCD_Members = Get-ADGroupMember -Identity $GroupName | Select name, SamAccountName
    
    
    ForEach ($Member in $CCD_Members){
        $user = [PSCustomObject]@{name=$null;email=$null}
        $user.email = Get-ADUser -Identity $Member.SamAccountName -properties mail | Select -expandproperty mail
        $user.name = $Member.name
        $arrUserObjects += ($user)
    }
    
    $arrUserObjects | Export-Csv $path
    
    $completionMessage = "File exported as '" + $path + "' Press enter key to exit"
}
CATCH {
  Write-Host "An error occurred:"
  Write-Host $_
  $completionMessage = "Failed!! check that you're running as Admin. Press enter key to exit"
}
Read-Host -Prompt $completionMessage
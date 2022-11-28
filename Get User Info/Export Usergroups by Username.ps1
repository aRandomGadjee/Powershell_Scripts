Clear

$user = Read-Host("Provide username")
$path = "C:\GPOs for User - "+ "$user"+".csv"
TRY{
    $c = Get-ADPrincipalGroupMembership -Identity $user | Select name, GroupScope, GroupCategory, SID
    
    $arrGroups = @()
    
    foreach($group IN $c)
    {
        $objGroup = [PSCustomObject]@{Name=$null;ObjectType=$null;SID=$null}
        $objGroup.Name = ($group).Name
        $objGroup.ObjectType = (($group).GroupScope,($group).GroupCategory -join " - ")
        $objGroup.SID = ($group).SID
        $arrGroups += ($objGroup)
    }
    $completionMessage = "File exported as '" + $path + "' Press enter key to exit"
    $arrGroups | Export-Csv $path
}
CATCH 
{
    Write-Host "An error occurred:"
    Write-Host $_
    $completionMessage = "Failed!! check that you're running as Admin. Press enter key to exit"
}
Read-Host -Prompt $completionMessage
# Powershell_Scripts
A collection of handy powershell scripts I've created

Most of my scripts are for a Windows environment with Active Directory - you're free to use them. I'm not the best with powershell and only really use it when I need too :)

Please don't come for me... I had wrote most of these scripts whilst doing ***my actual job*** for other users (usually either the 1st level support, or their managers).


## Files and Summaries
___
### Exchange and Email ❌ DEPRECATED
#### Get Delivery Report (exchange) by Sender Address.ps1
&nbsp;**Description**
&nbsp;&nbsp;    Creates a CSV (on your C: drive) of email delivery reports for the provided email address

&nbsp;**Inputs**
 - Sender Email Address
 - Number of days
___
### Get Device and AD info ❌ DEPRECATED
#### Get-Machine_Info.ps1
&nbsp;**Description**
&nbsp;&nbsp;    Returns Machine information from Active Directory for the provided "PC Name" (Get-ADComputer Identity property)

&nbsp;**Inputs**
- Identity Property
#### Get-name_and_email_from_group_member.ps1
&nbsp;**Description**
&nbsp;&nbsp;    Creates a CSV (in your default Documents Path) with the name of the group you're querying, containing Email Address and Name for users within that AD Group

&nbsp;**Inputs**
 - Name of the AD group to query
#### Get-Network_Drives.ps1
&nbsp;**Description**
    &nbsp;&nbsp;Returns the mapped Network Drives from Win32_MappedLogicalDisk for the provided "PC Name" (Win32_MappedLogicalDisk Computer property)

&nbsp;**Inputs**
 - Identity Property
___
### Get User Info
#### Export Usergroups by Username.ps1
&nbsp;**Description**
&nbsp;&nbsp;    Creates a CSV (on your C: drive) of all GPO's the provided user is a member of

&nbsp;**Inputs**
 - NTUsername
___
### Snippets
#### Spinner and PSJobs example.ps1
&nbsp;**Description**
&nbsp;&nbsp;    An example of a cool spinner, and how to use Powershell jobs
___
### User Accounts
#### Create Restricted User.ps1
&nbsp;**Description**
&nbsp;&nbsp;    Three jobs are ran, creating a new account, applying restrictions, then allowing FullControl of the new users Programs directory (so it can install apps without admin prompts)
&nbsp;&nbsp;&nbsp;    **Job 1**: Creates a new standard local user with the provided Username, Display name, and Password.
&nbsp;&nbsp;&nbsp;    **Job 2**: Restricts the User Account so it cannot see any other users data (ACL).
&nbsp;&nbsp;&nbsp;    **Job 3**: Creates the Programs directory (per-user) and gives the account FullControl

&nbsp;&nbsp; Execution ends if it encounters any errors

&nbsp;**Inputs**
 - Username
 - Display Name
 - Password
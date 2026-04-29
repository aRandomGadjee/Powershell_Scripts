# Powershell_Scripts
A collection of handy powershell scripts I've created

Most of my scripts are for a Windows environment with Active Directory - you're free to use them. I'm not the best with powershell and only really use it when I need too :)

Please don't come for me... I had wrote most of these scripts whilst doing ***my actual job*** for other users (usually either the 1st level support, or their managers).


## Files and Summaries
### Exchange and Email ❌ DEPRECATED
    #### Get Delivery Report (exchange) by Sender Address.ps1
    **Description**
        Creates a CSV (on your C: drive) of email delivery reports for the provided email address
    **Inputs**
        - Sender Email Address
        - Number of days 
### Get Device and AD info ❌ DEPRECATED
    #### Get-Machine_Info.ps1
    **Description**
        Returns Machine information from Active Directory for the provided "PC Name" (Get-ADComputer Identity property)
    **Inputs**
        Identity Property
    #### Get-name_and_email_from_group_member.ps1
     **Description**
        Creates a CSV (in your default Documents Path) with the name of the group you're querying, containing Email Address and Name for users within that AD Group
    **Inputs**
        - Name of the AD group to query
    #### Get-Network_Drives.ps1
    **Description**
        Returns the mapped Network Drives from Win32_MappedLogicalDisk for the provided "PC Name" (Win32_MappedLogicalDisk Computer property)
    **Inputs**
        Identity Property
### Get User Info
    #### Export Usergroups by Username.ps1
    **Description**
        Creates a CSV (on your C: drive) of all GPO's the provided user is a member of
    **Inputs**
        - NTUsername
### Snippets
    #### Spinner and PSJobs example.ps1
    **Description**
        An example of a cool spinner, and how to use Powershell jobs
### User Accounts
    #### Create Restricted User.ps1
    **Description**
        Three jobs are ran, creating a new account, applying restrictions, then allowing FullControl of the new users Programs directory (so it can install apps without admin prompts)
        Job 1: Creates a new standard local user with the provided Username, Display name, and Password.
        Job 2: Restricts the User Account so it cannot see any other users data (ACL).
        Job 3: Creates the Programs directory (per-user) and gives the account FullControl

        Execution ends if it encounters any errors
    **Inputs**
        - Username
        - Display Name
        - Password
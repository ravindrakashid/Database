
<#DB Params
[string]$ServerInstance = 'HostName\SQLEXPRESS'
[string]$Database = 'SSIS'
$UserID,$Password = Creds to cnnect to DB
$SQLScriptName = 'CreateDB'
$SQLScriptPath = "C:\Users\Ravi\Documents\SQL Server Management Studio\SQL Scripts\CreateDB.sql"
#>

<#
.Synopsis
   PowerShell script to create new MSSQL Database.
.DESCRIPTION
   The function creates a new MSSQL DB for an instance from a stored SQL script to which changes can be made as per the requirements.
   Create-MSSQLDB in MSSQL Server: Note this is to be executed only once in lifetime, Once DB(s)/Table(s) is created only table(s) needs to be updated.
   This is an automated script that will require the several user inputs/parameters and the DB is automatically created,attached and visble in the SSMS ocnsole.
   All the declared parameters are mandatory, the script also generates a success/failure audits and logs them to a logfile. Log file can further be used for troubleshhoting & references.
.EXAMPLE
   Create-MSSQLDB -ServerInstance 'HostName\SQLEXPRESS' -UserID 'DBAdmin' -Password '******' -SQLScriptName 'CreateDB' -SQLScriptPath 'C:\Users\Ravi\Documents\SQL Server Management Studio\SQL Scripts\CreateDB.sql' -ConnectionTimeOut '300'
.EXAMPLE
   Verify if the DB is created or not:
   Invoke-Sqlcmd -ServerInstance 'HostName\SQLEXPRESS' -Username 'DBAdmin' -Password '******' -Query "SELECT 'SSIS' AS [Current Database];" -ErrorAction Stop
.Author
    Ravindra Kashid (ravindra.kashid@outlook.com)
#>

#Load Modules
Import-Module -Name 'sqlserver'
Function Create-MSSQLDB() {

    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$ServerInstance,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserID,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$SQLScriptName,
        [Parameter(Mandatory = $true)]
        [string]$SQLScriptPath,
        [Parameter(Mandatory = $true)]
        [int]$ConnectionTimeOut
    )

    $DirectoryPath = "$env:USERPROFILE\Documents\SQL Server Management Studio\SQL Scripts\Logs"

    if (!(Test-Path -path $DirectoryPath )) {
        New-Item -ItemType directory -Path $DirectoryPath
    }
    if (!(Test-Path -Path "$DirectoryPath\$SQLScriptName*.txt")) {
        $DateTime = (Get-Date -Format "yyyyMMdd_HHmmss").ToString()
        $LogFile = $SQLScriptName + "_" + $DateTime + "_Log.txt"
        $LogFilePath = Join-Path $DirectoryPath -ChildPath $LogFile
    }
    else {
        $ExistingLog = Get-ChildItem -Path $DirectoryPath -Name "$SQLScriptName*" | Sort-Object -Descending | Select-Object -First 1
        $LogFile = $ExistingLog.TrimEnd(('\'))
        $LogFilePath = $DirectoryPath + "\" + $ExistingLog
    }

    $IsLogFileCreated = $false
    function Write-Log() {

        param (
            [ValidateSet("Error", "Information")]
            [string]$LogType,
            [string]$LogMsg,
            [string]$LogFunction
        )

        if (!$IsLogFileCreated) {
            Write-Host "Creating Log File..."
            if (!(Test-Path -path $DirectoryPath)) {
                Write-Host "Please Provide Proper Log Path" -ForegroundColor Red
            }
            else {
                $script:IsLogFileCreated = $True
                Write-Host "Logs written to [$LogFile]"
                [string]$LogMessage = [System.String]::Format("[$(Get-Date)] - [{0}] -[{1}] - {2}", $LogType, $LogFunction, $LogMsg)
                Add-Content -Path $LogFilePath -Value $LogMessage
            }
        }
        else {
            [string]$LogMessage = [System.String]::Format("[$(Get-Date)] - [{0}] -[{1}] - {2}", $LogType, $LogFunction, $LogMsg)
            Add-Content -Path $LogFilePath -Value $LogMessage
        }
    }

    try {
        [SecureString]$SecureString = $Password | ConvertTo-SecureString -AsPlainText -Force
        [PSCredential]$DBCreds = New-Object System.Management.Automation.PSCredential -ArgumentList $UserID, $SecureString
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Credential $DBCreds -InputFile $SQLScriptPath -ConnectionTimeout $ConnectionTimeOut -ErrorAction Stop -Verbose
        Write-Log -LogType Information -LogFunction "Function: Create-MSSQLDB" -LogMsg "Successfully created Reporting Database"
    }
    catch {
        $ErrorMessage = $Error[0].exception.message
        Write-Host $ErrorMessage -ForegroundColor Yellow
        Write-Log -LogType Error -LogFunction "Function: Create-MSSQLDB" -LogMsg $ErrorMessage
    }
}





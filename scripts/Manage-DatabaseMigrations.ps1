<#
.SYNOPSIS
  Imports a CSV dataset into a table
#>
[cmdletbinding()]
[OutputType([String])]
param(
    [Parameter(Mandatory = $True)]
    [String]
    [ValidateSet("Add", "Script", "Apply")]
    $Action,

    [Parameter(Mandatory = $False)]
    [String]
    $MigrationName = "",

    [Parameter(Mandatory = $False)]
    [String]
    $ProjectPath = "$PSScriptRoot\..\ApplicationApi\Azure.CI.CD.Demo.API",

    [Parameter(Mandatory = $False)]
    [String]
    $ScriptFileName = "$PSScriptRoot\migrations.sql",

    [Parameter(Mandatory = $False)]
    [String]
    $TargetServer = "(LocalDB)\MSSQLLocalDB",

    [Parameter(Mandatory = $False)]
    [String]
    $DatabaseName = "AzureCiCdDemo",

    [Parameter(Mandatory = $False)]
    [String]
    $DatabasePath = "$($env:USERPROFILE)\$DatabaseName.mdf",

    [Parameter(Mandatory = $False)]
    [String]
    [ValidateSet("Trusted", "Password")]
    $AuthenticationType = "Trusted",

    [Parameter(Mandatory = $False)]
    [String]
    $UserName = "",

    [Parameter(Mandatory = $False)]
    [securestring]
    $Password
)

if ($Action -eq "Apply" -and -not (Get-Command SQLCMD -ErrorAction SilentlyContinue)) {
    Write-Error "SQLCMD is not installed." 
    exit 1
}

switch ($Action) {
    "Add" {
        if ($MigrationName -eq "" -or $MigrationName -like "* *") {
            Write-Error "You must provide a migration name with no spaces"
            exit 1
        }
        Push-Location
        Set-Location $ProjectPath
        try {
            Write-Verbose "Creating migration $MigrationName"
            dotnet ef migrations add $MigrationName
            Write-Verbose "Current migrations"
            if ($VerbosePreference -ne "SilentlyContinue") {
                Get-ChildItem .\Migrations
            }
        }
        catch {
            Write-Error "Could not create migration"
        }
        Pop-Location
    }
    "Script" { 
        Push-Location
        Set-Location $ProjectPath
        try {
            Write-Error "Let me out!"
            Write-Verbose "Creating migration script"
            dotnet ef migrations script --idempotent --output $ScriptFileName
            Write-Verbose "Created migration script at $ScriptFileName"
        }
        catch {
            Write-Error "Could not create migration script"
        }
        Pop-Location
    }
    "Apply" {
        if ($AuthenticationType -eq "Password" -and $UserName -eq "") {
            Write-Error "You must provide a username and password"
            $credentials = New-Object Management.Automation.PSCredential($UserName, $Password)
        }
        if ($AuthenticationType -eq "Trusted") {
            $result = (SQLCMD.EXE -S "$TargetServer" -d master -E -Q "SELECT COUNT(*) FROM sys.databases WHERE [Name] = '$DatabaseName'")
        }
        else {
            $result = (SQLCMD.EXE -S "$TargetServer" -d master -U $credentials.UserName -P $credentials.Password -Q "SELECT COUNT(*) FROM sys.databases WHERE [Name] = '$DatabaseName'")
        }
        $dbCount = [System.Convert]::ToInt16($result[2])
        if ($dbCount -eq 0) {
            if ([System.IO.Path]::IsPathRooted($DatabasePath)) {
                $absoluteDatabasePath = $DatabasePath
            }
            else {
                $absoluteDatabasePath = Join-Path $PWD $DatabasePath
            }
            $parentFolder = Split-Path "$absoluteDatabasePath" -Parent
            if (!(Test-Path $ParentFolder)) {
                Write-Verbose "Folder $parentFolder does not exist. Creating it now."
                (New-Item -Path $parentFolder -ItemType Directory) | Out-Null
            }
            Write-Verbose "Database $DatabaseName does not yet exist in instance $TargetServer"
            Write-Verbose "Creating database $DatabaseName at $absoluteDatabasePath"
            $logPath = $absoluteDatabasePath -replace "\.mdf$", "_log.ldf"
            $cmd = "CREATE DATABASE [$DatabaseName] `
            ON PRIMARY (NAME=$($DatabaseName)_data, FILENAME = '$absoluteDatabasePath') `
            LOG ON (NAME=$($DatabaseName)_log, FILENAME = '$logPath')"
            if ($AuthenticationType -eq "Trusted") {
                SQLCMD.EXE -S "$TargetServer" -d master -E -Q "$cmd"
            }
            else {
                SQLCMD.EXE -S "$TargetServer" -d master -U $credentials.UserName -P $credentials.Password -Q "$cmd"
            }
        }
        else {
            Write-Verbose "Database $DatabaseName already exists in instance $TargetServer"
        }
        Write-Verbose "Applying migrations from $ScriptFileName to $TargetServer"
        if ($AuthenticationType -eq "Trusted") {
            SQLCMD.EXE -S $TargetServer -d $DatabaseName -E -i $ScriptFileName
        }
        else {
            SQLCMD.EXE -S $TargetServer -d $DatabaseName -U $credentials.UserName -P $credentials.Password -i $ScriptFileName
        }
    }
    Default {}
}

<#
.SYNOPSIS
  Imports a CSV dataset into a table, replacing all prior data
#>
[cmdletbinding()]
[OutputType([String])]
param(
    [Parameter(Mandatory = $False)]
    [String]
    $TargetDatabaseName = "AzureCiCdDemo",

    [Parameter(Mandatory = $False)]
    [String]
    $SourceFolder = "$PSScriptRoot\SeedData",

    [Parameter(Mandatory = $False)]
    [String[]]
    $CsvFiles = (Get-ChildItem $SourceFolder\*.csv | ForEach-Object { $_.fullname }),

    [Parameter(Mandatory = $False)]
    [String]
    $TargetServer = "(LocalDB)\MSSQLLocalDB",

    [Parameter(Mandatory = $False)]
    [String]
    $TargetSchemaName = "dbo",

    [Parameter(Mandatory = $False)]
    [String]
    $RecordDelimiter = "!~!",
  
    [switch]
    $KeepBcpFiles = $false
)

if (-not (Get-Command bcp -ErrorAction SilentlyContinue)) {
    Write-Error "BCP is not installed." 
    Return
}

if (-not (Get-Command SQLCMD -ErrorAction SilentlyContinue)) {
    Write-Error "SQLCMD is not installed." 
    Return
}


Write-Verbose "Disabling foreign key contraints"
SQLCMD.EXE -S $TargetServer -d $TargetDatabaseName -E -Q "EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT all'"

foreach ($csvFile in $CsvFiles) {
    $csvFile = (Get-Item $csvFile)
    $tableName = $csvFile.BaseName
    Write-Verbose "Processing table : $tablename"
    $bcpFileName = "$($csvFile.BaseName).bcp"
    Remove-Item $bcpFileName -Force -ErrorAction SilentlyContinue

    foreach ($row in (Import-Csv -Path $csvFile -Encoding ASCII)) {
        $row.psobject.Properties.value -JOIN "$RecordDelimiter" | Add-Content -Path $bcpFileName -Encoding ASCII       
    }

    Write-Verbose "Enabling identity insertion"
    SQLCMD.EXE -S $TargetServer -d $TargetDatabaseName -E -Q "SET IDENTITY_INSERT [$TargetSchemaName].[$tableName] ON"
    Write-Verbose "Truncating table"
    SQLCMD.EXE -S $TargetServer -d $TargetDatabaseName -E -Q "TRUNCATE TABLE [$TargetSchemaName].[$tableName]"
    Write-Verbose "Inserting data"
    bcp.exe "[$TargetDatabaseName].[$TargetSchemaName].[$tableName]" in $bcpFileName -S $TargetServer -T -c -CACP -t"$RecordDelimiter"
    Write-Verbose "Disabling identity insertion"
    SQLCMD.EXE -S $TargetServer -d $TargetDatabaseName -E -Q "SET IDENTITY_INSERT [$TargetSchemaName].[$tableName] OFF"

    if (-not($KeepBcpFiles)) {
        Remove-Item $bcpFileName -Force -ErrorAction SilentlyContinue
    }
}

Write-Verbose "Enabling foreign key contraints"
SQLCMD.EXE -S $TargetServer -d $TargetDatabaseName -E -Q "EXEC sp_msforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all'"

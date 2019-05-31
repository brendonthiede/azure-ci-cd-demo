# Azure CI/CD Demo

## Overview

This project will be used to show a basic CI/CD pipeline for an application in Azure.

## Prerequisites

You will need the following installed for this project to work:

* [.NET Core 2.2](https://dotnet.microsoft.com/download)
* [Node 10.15.3 (or possibly newer, I just stick to LTS)](https://nodejs.org/dist/v10.15.3/node-v10.15.3-x64.msi)
* Angular CLI: `npm install -g @angular/cli`
* Az PowerShell module: `Install-Module -Name Az -AllowClobber -Scope CurrentUser`

## Making Your Own Application

To make your own project like this, you can the repo and application ready like this:

```powershell
function New-DotNetCoreSolution {
    Param(
        [string] [Parameter(Mandatory=$true)] $ProjectBasename,
        [string] [Parameter(Mandatory=$true)] [ValidateSet("mvc","webapi","razor","angular","classlib","console","web")] $ProjectType,
        [string] [Parameter(Mandatory=$true)] $SolutionRoot
    )

    dotnet new sln --name "$ProjectBasename" --output "$SolutionRoot"
    dotnet new $ProjectType --name "$ProjectBasename" --output "$SolutionRoot\$ProjectBasename"
    dotnet new xunit --name "$ProjectBasename.Tests" --output "$SolutionRoot\$ProjectBasename.Tests"

    Push-Location
    Set-Location $SolutionRoot
    ".vs/`n[Bb]in/`n[Oo]bj/" | Set-Content .gitignore
    dotnet dev-certs https --trust
    dotnet sln add ".\$ProjectBasename\$ProjectBasename.csproj"
    dotnet sln add ".\$ProjectBasename.Tests\$ProjectBasename.Tests.csproj"
    Set-Location -Path "$ProjectBasename.Tests"
    dotnet add reference "../$ProjectBasename/$ProjectBasename.csproj"
    Pop-Location
}

New-Item -ItemType Directory -Name azure-ci-cd-demo
Set-Location azure-ci-cd-demo
git init
New-Item -ItemType Directory -Name "scripts"
New-Item -ItemType Directory -Name "scripts\SeedData"
New-DotNetCoreSolution -ProjectBasename "Azure.CI.CD.Demo.API" -ProjectType "webapi" -SolutionRoot ".\ApplicationApi"
ng new azure-ci-cd-demo-ui --directory ".\ApplicationUi" --routing true --style sass --skip-git true

git add .
git commit -m "Initial commit"
```

## Entity Framework Migrations

### Generating Migrations

It is best practice to keep entities and models as two different things ([read more here](https://docs.microsoft.com/en-us/dotnet/standard/microservices-architecture/microservice-ddd-cqrs-patterns/infrastructure-persistence-layer-implemenation-entity-framework-core) and [research AutoMapper here](https://automapper.org/)), but for simplicity here there is only `Model.cs` that contains all the database models, which will be used directly in the application.

To create "code first" migrations, start by creating your models in code (classes in `Model.cs` in this case), and then run the following command from the project folder (`ApplicationApi\Azure.CI.CD.Demo.API`):

```powershell
dotnet ef migrations add InitialCreate
```

### Applying Migrations

In a development environment, you can then apply the migrations by simply starting up the application. The connection string in `ApplicationApi\Azure.CI.CD.Demo.API\appsettings.Development.json` will be used to connect to LocalDB and apply the migrations at start up. However, this is not the best way to do things in higher environments, in particular since the principle of least privilege would propose that the database connection that the application uses _only_ has the access it needs, i.e. the app should only be able to select, insert, update, and delete (DML using `db_datareader` and `db_datawriter` roles), and not be able to perform schema changes, etc. (DDL using `db_owner` role).

For higher environments you should generate a SQL script and run that script as a user with the `db_owner` role. First generate the script by running something like this from the project folder (`ApplicationApi\Azure.CI.CD.Demo.API`):

```powershell
dotnet ef migrations script --idempotent --output ../../scripts/migrations.sql
```

Please note that this is a generated file, so it should not be stored in source control, but should instead be generated as a build artifact when using it in a CI pipeline. Now to apply the migrations you go to the `scripts` folder and run something like the following:

```powershell
SQLCMD.EXE -S "(LocalDB)\MSSQLLocalDB" -d master -E -i migrations.sql
```
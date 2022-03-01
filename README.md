# ASP.NET Core Sample for Helm and K8s on Raspberry Pi

## Setup

```powershell
mkdir dotnet-webapi
cd .\dotnet-webapi\
mkdir src\webapi
mkdir DevOps\Docker
cd src
dotnet new sln
dotnet new webapi -o dotnet-webapi
dotnet sln add .\dotnet-webapi\dotnet-webapi.csproj
```

```powershell
copy ..\dotnet-console\run.ps1 .
copy ..\dotnet-console\.gitignore
dir
git init
git add .
git commit -am 'initial commit'
```

Use VSCode to add Dockerfile, and move to DevOps/Docker/Dockerfile

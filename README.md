# ASP.NET Core Sample for Kubernetes and Helm on Raspberry Pis

This is the source repo for [my blog post](https://seekatar.github.io/2022/03/08/k8s-rpi.html) about setting up Kubernetes on Pis.

A [CHECKLIST](CHECKLIST.md) is a very terse version of all the steps needed to set up the Pis as described in the blog.

## How this was created

This hasn't been altered too much from the template. See the blog for details.

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

After the project was created, copy a couple common files and init git.

```powershell
copy ..\dotnet-console\run.ps1 . # steal a couple common file
copy ..\dotnet-console\.gitignore
dir
git init
git add .
git commit -am 'initial commit'
```

I used VSCode to add a `Dockerfile`, and moved it to `DevOps/Docker/Dockerfile`

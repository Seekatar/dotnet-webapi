#! pwsh
param (
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $runFile = (Join-Path (Split-Path $commandAst -Parent) run.ps1)
        if (Test-Path $runFile) {
            Get-Content $runFile |
                    Where-Object { $_ -match "^\s+'([\w+-]+)' {" } |
                    ForEach-Object {
                        if ( !($fakeBoundParameters[$parameterName]) -or
                            (($matches[1] -notin $fakeBoundParameters.$parameterName) -and
                             ($matches[1] -like "$wordToComplete*"))
                            )
                        {
                            $matches[1]
                        }
                    }
        }
     })]
    [string[]] $Tasks,
    [switch] $DryRun
)

$currentTask = ""
$localPort = 8081
$aspNetPort = 80
$ASPNETCORE_URLS="http://+:$aspNetPort"

# execute a script, checking lastexit code
function executeSB
{
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [scriptblock] $ScriptBlock,
    [string] $WorkingDirectory,
    [string] $TaskName = $currentTask
)
    if ($WorkingDirectory) {
        Push-Location (Join-Path $PSScriptRoot $WorkingDirectory)
    } else {
        Push-Location $PSScriptRoot
    }
    try {
        $global:LASTEXITCODE = 0

        Invoke-Command -ScriptBlock $ScriptBlock

        if ($LASTEXITCODE -ne 0) {
            throw "Error executing command '$TaskName', last exit $LASTEXITCODE"
        }
    } finally {
        if ($WorkingDirectory) {
            Pop-Location
        }
    }
}

$imageName = 'dotnet-webapi'
$dockerRegistry = 'k3s-server:5000'

foreach ($currentTask in $Tasks) {

    try {
        $prevPref = $ErrorActionPreference
        $ErrorActionPreference = "Stop"

        "-------------------------------"
        "Starting $currentTask"
        "-------------------------------"

        switch ($currentTask) {
            'build' {
                executeSB 'src' {
                    dotnet build
                }
            }
            'run' {
                executeSB -WorkingDirectory "src/$imageName" {
                    dotnet run
                }
            }
            'runDocker' {
                executeSB {
                    docker run --rm `
                               --publish ${localPort}:$aspNetPort `
                               --env "ASPNETCORE_URLS=$ASPNETCORE_URLS" `
                               --env "ASPNETCORE_HTTPS_PORT=8081" `
                               --interactive `
                               --tty `
                               --name $imageName `
                               "${imageName}:latest"
                }
              }
            'buildDocker' {
                executeSB -WorkingDirectory 'src/dotnet-webapi' {
                    docker build --rm `
                                 --tag ${imageName}:latest `
                                 --file ../../DevOps/Docker/Dockerfile `
                                 .
                }
            }
            'pushDocker' {
                executeSB {
                    docker image tag $imageName $dockerRegistry/$imageName
                    docker push $dockerRegistry/$imageName
                }
            }
            'installHelm' {
                $valuesFile = Join-Path $PSScriptRoot DevOps/helm/values.yaml
                $outputFile = Join-Path $env:Temp dry-run.yaml
                if ($DryRun) {
                    executeSB 'DevOps/helm' {
                        helm install DRY-RUN . --dry-run --values $valuesFile | ForEach-Object {
                            $_ -replace "LAST DEPLOYED: .*","LAST DEPLOYED: NEVER"
                        } | Out-File $outputFile -Append
                        "Output in now $outputFile"
                    }
                } else {
                    executeSB 'DevOps/helm' {
                        helm install $imageName . --values $valuesFile
                    }
                }
            }
            'uninstallHelm' {
                executeSB {
                    helm uninstall $imageName
                }
            }
            default {
                throw "Invalid task name $currentTask"
            }
        }

    } finally {
        $ErrorActionPreference = $prevPref
    }
}

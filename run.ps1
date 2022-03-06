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
    [switch] $DryRun,
    [switch] $Wait,
    [string] $Tag = [DateTime]::Now.ToString("MMdd-HHmmss")
)

$currentTask = ""
$localPort = 8081
$aspNetPort = 8080
$ASPNETCORE_URLS="http://+:$aspNetPort"

# execute a script, checking lastexit code
function executeSB
{
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [scriptblock] $ScriptBlock,
    [string] $RelativeDir,
    [string] $Name = $currentTask
)
    if ($RelativeDir) {
        Push-Location (Join-Path $PSScriptRoot $RelativeDir)
    } else {
        Push-Location $PSScriptRoot
    }
    try {
        $global:LASTEXITCODE = 0

        Invoke-Command -ScriptBlock $ScriptBlock

        if ($LASTEXITCODE -ne 0) {
            throw "Error executing command '$Name', last exit $LASTEXITCODE"
        }
    } finally {
        Pop-Location
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
                executeSB -RelativeDir "src/$imageName" {
                    dotnet run
                }
            }
            'runDocker' {
                executeSB {
                    docker run --rm `
                               --publish ${localPort}:$aspNetPort `
                               --env "ASPNETCORE_URLS=$ASPNETCORE_URLS" `
                               --env "ASPNETCORE_HTTPS_PORT=$aspNetPort" `
                               --interactive `
                               --tty `
                               --name $imageName `
                               "${imageName}:$Tag"
                }
              }
            'buildDocker' {
                executeSB -RelativeDir 'src/dotnet-webapi' {
                    docker build --rm `
                                 --tag ${imageName}:$Tag `
                                 --file ../../DevOps/Docker/Dockerfile `
                                 .
                }
            }
            'pushDocker' {
                executeSB {
                    docker image tag ${imageName}:$Tag $dockerRegistry/${imageName}:$Tag
                    docker push $dockerRegistry/${imageName}:$Tag
                }
            }
            'stopDocker' {
                executeSB {
                    docker stop $imageName
                }
            }
            'installHelm' {
                $valuesFile = Join-Path $PSScriptRoot DevOps/helm/values.yaml

                $sets = @(
                    '--set', "image.tag=$Tag"
                )

                if ($DryRun) {
                    $outputFile = Join-Path $env:Temp dry-run.yaml
                    Remove-Item $outputFile -ErrorAction Ignore | Out-Null

                    executeSB -R 'DevOps/helm' {
                        helm install $imageName . --dry-run --values $valuesFile | ForEach-Object {
                            $_ -replace "LAST DEPLOYED: .*","LAST DEPLOYED: NEVER"
                        } | Out-File $outputFile -Append
                        "Output in now $outputFile"
                    }
                } else {
                    executeSB -R 'DevOps/helm' {
                        $extra = @()
                        if ($Wait) {
                            $extra += '--wait'
                        }
                        helm upgrade --install --values $valuesFile $imageName @sets . @extra
                    }
                }
            }
            'uninstallHelm' {
                try {
                    executeSB {
                        helm uninstall $imageName
                    }
                } catch {}
            }
            default {
                throw "Invalid task name $currentTask"
            }
        }

    } finally {
        $ErrorActionPreference = $prevPref
    }
}

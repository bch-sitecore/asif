[CmdletBinding()]
Param(
  [Parameter()]
  [string]$Repository = "asif"
  ,
  [switch]$Publish
)
$ErrorActionPreference = "Stop"

.\Build.Src.ps1

Write-Output "Setting up builds"
$builds = @()

# It takes ~20 minutes for AV to pull a microsoft/aspnet image. AV has a cached
# version (w/ digest below) so we're going to try to use that. :fingers_crossed:
# @sha256:7cdafe834e1c08ed880cd54183ba33d4760c8b19e651ef1cbff0cf3118684e88
#  a.k.a microsoft/aspnet:latest as of 09.28.2017
$builds += @{ Base = "microsoft/aspnet:latest"; Tag = @("sc90u2-aspnet4.7.2") }
# older asp.net builds
# $builds += @{ Base = "microsoft/aspnet:4.7.1"; Tag = @("sc90u2-aspnet4.7.1") }
# $builds += @{ Base = "microsoft/aspnet:4.7"; Tag = @("sc90u2-aspnet4.7") }
# $builds += @{ Base = "microsoft/aspnet:4.6.2"; Tag = @("sc90u2-aspnet4.6.2") }

($builds | Select-Object -First 1).Tags += "latest"

$builds | ForEach-Object {
  $base = $_.Base
  $dockerfile = If ($_.ContainsKey("Dockerfile") -and $_.Dockerfile) { $_.Dockerfile } { $null }
  $tag = $_.Tag

  $buildArgs = @("build")
  $buildArgs += @("--build-arg", "BASEIMAGE=${base}")
  $tag | ForEach-Object { $buildArgs += @("--tag", "${Repository}:${_}") }
  If ($dockerfile) { $buildArgs += @("--file", $dockerfile) }
  $buildArgs += "."

  Write-Output "Building ${Repository}:${tag} atop ${base}"
  & docker $buildArgs
  If ($LASTEXITCODE) {
    Write-Error "Non-zero exit code ${LASTEXITCODE} while building ${tag}"
  } ElseIf ($Publish) {
    $tag | ForEach-Object {
      Write-Output "Publishing ${Repository}:${_} to docker"
      docker push "${Repository}:${_}"
    }
  }
}

Write-Output "Build complete."
[CmdletBinding(DefaultParameterSetName = "__filter")]
Param(
  [Parameter(Position = 0, ParameterSetName = "__filter")]
  [AllowEmptyCollection()]
  [string[]]$Filter = ("*")
  ,
  [Parameter(Position = 0, ParameterSetName = "__numeric")]
  [ValidateRange(1, 99)]
  [Alias("GTE")]
  [int]$StartAt
)
$ErrorActionPreference = "Stop"

Function ConvertTo-PrettyJson {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [String] $json
  )
  Process {
    $indent = 0;
    ($json -Split '\n' |
      % {
        if ($_ -match '[\}\]],?\s*$') {
          # This line contains  ] or }, decrement the indentation level
          $indent--
        }
        $line = (' ' * $indent * 2) + $_.TrimStart().Replace(':  ', ': ')
        if ($_ -match '[\{\[]\s*$') {
          # This line contains [ or {, increment the indentation level
          $indent++
        }
        $line
    }) -Join "`n"
  }
}
Function ConvertTo-Hashtable {
  Param(
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [PSCustomObject]$InputObject
  )
  Begin { $ht = @{} }
  Process {
    $InputObject.PSObject.Properties | ForEach-Object {
      $ht[$_.Name] = $_.Value
    }
  }
  End { $ht }
}
Function Get-Properties {
  [CmdletBinding(DefaultParameterSetName = "__param")]
  Param(
    [Parameter(Position = 0, Mandatory = $true, ParameterSetName = "__param")]
    [Parameter(ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "__pipe")]
    [ValidateNotNull()]
    [PSCustomObject]$InputObject
  )
  Process {
    $InputObject.PSObject.Members | Where-Object { $_.MemberType -eq "NoteProperty" }
  }
}
Function Test-Filter {
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string[]]$Filter
    ,
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Target
  )
  Process {
    ($Filter -contains $Target) -or ($null -ne ($Filter | Where-Object { $Target -like $_ }))
  }
}
Function Test-Property {
  [CmdletBinding(DefaultParameterSetName = "__param")]
  Param(
    [Parameter(Position = 0, Mandatory = $true, ParameterSetName = "__param")]
    [Parameter(ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "__pipe")]
    [ValidateNotNull()]
    [PSCustomObject]$InputObject
    ,
    [Parameter(Position = 1, Mandatory = $true, ParameterSetName = "__param")]
    [Parameter(Position = 0, Mandatory = $true, ParameterSetName = "__pipe")]
    [ValidateNotNullOrEmpty()]
    [Alias("Name")]
    [string]$PropertyName
  )
  Process {
    $null -ne (Get-Properties $InputObject | Where-Object { $_.Name -eq $PropertyName })
  }
}

$configs = @()
$baseimage = "microsoft/aspnet:latest"
$context = Convert-Path "${PSScriptRoot}\.."

& ${context}\Build.src.ps1

Get-ChildItem $PSScriptRoot -Include "Dockerfile" -Recurse | ForEach-Object {
  $buildContext = $_.Directory
  $tag = Split-Path $_.Directory -Leaf
  If ($tag -like "*.ignore") { Return }

  $configJson = "${buildContext}\resourcefiles\config.json"
  If (Test-Path $configJson) {
    $configs += Get-Content $configJson |
      Where-Object { $_ -notmatch "(^|\s*)//*" } |
      Out-String | ConvertFrom-Json
  }
  
  If ($PSCmdlet.ParameterSetName -eq "__filter" -and !(Test-Filter $Filter -Target $tag)) {
    Write-Output "Skipping ${tag} (filter applied, ${Filter})"
    $baseimage = "asif:${tag}"
    Return
  } ElseIf ($PSCmdlet.ParameterSetName -eq "__numeric") {
    If ([int]($tag -replace "layer") -lt $StartAt) {
      Write-Output "Skipping ${tag} (range applied, >= ${StartAt})"
      $baseimage = "asif:${tag}"
      Return
    }
  }

  $files = Get-Content "${buildContext}\files" -ErrorAction SilentlyContinue
  If ($files) {
    Write-Output "Copying ${files} to ${buildcontext}\resourcefiles"
    Get-ChildItem "${context}\resourcefiles\" -Include $files -Recurse | Copy-Item -Destination "${buildContext}\resourcefiles\"
  }

  Try {
    $buildArgs = @(
      "build",
      "--tag", "asif:${tag}",
      "--build-arg", "BASEIMAGE=${baseimage}",
      $buildContext
    )

    Write-Output "Building: docker ${buildArgs}"
    & docker $buildArgs
    If ($LASTEXITCODE) {
      Write-Error "Non-zero exit code ${LASTEXITCODE} while building ${tag}"
    }
    $baseimage = "asif:${tag}"
  } Catch {
    Write-Output "Build failed: asif:${tag}"
  } Finally {
    Write-Output "Cleaning ${buildcontext}\resourcefiles"
    If ($files) {
      Get-Childitem "${buildContext}\resourcefiles\" -Exclude "config.json" |
        Where-Object { Test-Path $_ -PathType Leaf } | Remove-Item
    }
  }
}

$combined = $configs | Select-Object -First 1
$configs | Select-Object -Skip 1 | ForEach-Object {
  $config = $_

  @("Parameters", "Variables", "Tasks") | ForEach-Object {
    $section = $_

    Write-Verbose "Section ${section}"
    If (Test-Property $config -PropertyName $section) {
      $config.$section.PSObject.Properties | ForEach-Object {
        $propName = $_.name
        $propValue = $_.Value

        Write-Verbose "  ${propName} (${propValue})"
        If (!(Test-Property $combined -PropertyName $section)) {
          $combined | Add-Member -MemberType NoteProperty -Name $section -Value (New-Object PSObject)
        }
        If (!(Test-Property $combined.$section -PropertyName $propName)) {
          Write-Verbose "    Added to combined"
          $combined.$section | Add-Member -Type NoteProperty -Name $propName -Value $propValue
        }
      }
    }
  }

  $combined | ConvertTo-Json | ConvertTo-PrettyJson | Set-Content "${context}\resourcefiles\combined-config.json"
}

<#
#Copy-Item C:\Windows\System32\drivers\etc\hosts -Destination $env:USERPROFILE\hosts
Copy-Item $env:USERPROFILE\hosts -Destination C:\Windows\System32\drivers\etc\hosts

$cid = docker run --rm -d asif:layer99
$ip = docker inspect $cid --format "{{.NetworkSettings.Networks.nat.IPAddress}}"

@(
  "${ip} xp0.sc"
  "${ip} xp0.xconnect"
) | Add-Content C:\Windows\System32\drivers\etc\hosts
#>
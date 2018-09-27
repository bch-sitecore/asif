<#
  .SYNOPSIS
    Adds a path to the PATH environmental variable.
  .PARAMETER Path
    Path to add.
  .PARAMETER EnvironmentVariableTarget
    Environmental variable target (scope).
#>
Function AddPath {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$Path
    ,
    [Parameter(Position = 1)]
    [ValidateSet([EnvironmentVariableTarget]::Machine, [EnvironmentVariableTarget]::Process, [EnvironmentVariableTarget]::User)]
    [Alias("Target")]
    [string]$EnvironmentVariableTarget = [EnvironmentVariableTarget]::Machine
  )
  Begin {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", $EnvironmentVariableTarget)
    $pathSeparator = [System.IO.Path]::PathSeparator
  }
  Process {
    If ($PSCmdlet.ShouldProcess($Path, "Add to `$env:PATH in $($EnvironmentVariableTarget) scope")) {
      $paths = $currentPath -split $pathSeparator | Where-Object { !([string]::IsNullOrWhiteSpace($_)) }
      If ($paths -notcontains $Path) {
        $paths += $Path
        $newPath = $paths -join $pathSeparator
        [Environment]::SetEnvironmentVariable("Path", $newPath, $EnvironmentVariableTarget)
      }
    }
  }
  End {
    UpdatePath
  }
}

<#
  .SYNOPSIS
    Removes a path from the PATH environmental variable.
  .PARAMETER Path
    Path to remove.
  .PARAMETER EnvironmentVariableTarget
    Environmental variable target (scope).
#>
Function RemovePath {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$Path
    ,
    [Parameter(Position = 1)]
    [ValidateSet("Machine", "Process", "User")]
    [Alias("Target")]
    [string]$EnvironmentVariableTarget = [EnvironmentVariableTarget]::Machine
  )
  Begin {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", $EnvironmentVariableTarget)
    $pathSeparator = [System.IO.Path]::PathSeparator
  }
  Process {
    If ($PSCmdlet.ShouldProcess($Path, "Remove from `$env:PATH in $($EnvironmentVariableTarget) scope")) {
      $paths = $currentPath -split $pathSeparator | Where-Object { !([string]::IsNullOrWhiteSpace($_)) }
      If ($paths -contains $Path) {
        $paths = $paths | Where-Object { $_ -ne $Path }
        $newPath = $paths -join $pathSeparator
        If ($newPath -ne $currentPath) {
          [Environment]::SetEnvironmentVariable("Path", $newPath, $EnvironmentVariableTarget)
        }
      }
    }
  }
  End {
    UpdatePath
  }
}

<#
  .SYNOPSIS
    Refreshes $env:Path variable from environmental store.
#>
Function UpdatePath {
  [CmdletBinding()]
  Param()
  Process {
    $env:Path = @(
      [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine),
      [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    ) -join [System.IO.Path]::PathSeparator
  }
}
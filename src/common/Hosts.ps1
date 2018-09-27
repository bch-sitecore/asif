<#
  .SYNOPSIS
    Adds an entry in the HOSTS file.

  .PARAMETER Hostname
    The hostname to create.
  .PARAMETER IPAddress
    The IP address to map.
  .PARAMETER Hosts
    The path to the hosts file.
#>
Function AddHostsEntry {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Hostname
    ,
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$IPAddress
    ,
    [Parameter(Position = 2)]
    [ValidateScript({ Test-Path $_ -PathType "Leaf" })]
    [string]$Hosts = (Join-Path $env:windir -ChildPath "System32\drivers\etc\hosts")
  )
  Process {
    $existing = GetHostsEntry $Hostname -Hosts $Hosts
    If (($existing -ne $IPAddress) -and $PSCmdlet.ShouldProcess($Hosts, "Add $($IPAddress) $($Hostname)")) {
      "$($IPAddress)`t$($Hostname)" | Add-Content $Hosts
    }
  }
}

<#
  .SYNOPSIS
    Retrieves an entry from the HOSTS file.

  .PARAMETER Hostname
    The hostname to retrieve.
  .PARAMETER Hosts
    The path to the hosts file.
#>
Function GetHostsEntry {
  [CmdletBinding()]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Hostname
    ,
    [Parameter(Position = 1)]
    [ValidateScript({ Test-Path $_ -PathType "Leaf" })]
    [string]$Hosts = (Join-Path $env:windir -ChildPath "System32\drivers\etc\hosts")
  )
  Begin {
    $escapedHostname = [regex]::Escape($Hostname)
  }
  Process {
    $match = Get-Content $Hosts |
      Where-Object { $_ -notmatch "^\s*#" } |
      Select-String "\b$($EscapedHostname)\b" |
      Select-Object -First 1
    If ($match -match "^\s*([\d\.]+|[0-9a-f\:]+)\b") {
      $Matches[1]
    }
  }
}

<#
  .SYNOPSIS
    Removes an entry from the HOSTS file.

  .PARAMETER Hostname
    The hostname to create.
  .PARAMETER Hosts
    The path to the hosts file.
#>
Function RemoveHostsEntry {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Hostname
    ,
    [Parameter(Position = 1)]
    [ValidateScript({ Test-Path $_ -PathType "Leaf" })]
    [string]$Hosts = (Join-Path $env:windir -ChildPath "System32\drivers\etc\hosts")
  )
  Begin {
    $escapedHostname = [regex]::Escape($Hostname)
  }
  Process {
    $existing = GetHostsEntry $Hostname -Hosts $Hosts
    If ($existing -and $PSCmdlet.ShouldProcess($Hosts, "Remove $($Hostname)")) {
      $contents = Get-Content $Hosts
      $contents | Where-Object { $_ -notmatch "\s$($escapedHostname)(?:\s|$)" } | Set-Content $Hosts
    }
  }
}
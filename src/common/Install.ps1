Function InstallExe {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Url
    ,
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutFile
    ,
    [Parameter(Position = 2)]
    [AllowEmptyCollection()]
    [string[]]$ArgumentList = @("/quiet", "/norestart")
  )
  Process {
    If (!(Test-Path $OutFile) -and $PSCmdlet.ShouldProcess($OutFile, "Download")) {
      Write-Verbose "Downloading $($OutFile)"
      Invoke-WebRequest $Url -OutFile $OutFile -UseBasicParsing
    }
    If ($PSCmdlet.ShouldProcess($OutFile, "Install")) {
      Write-Verbose "Installing $($OutFile) ($($ArgumentList -join ' '))"
      $result = Start-Process $OutFile -ArgumentList $ArgumentList -Wait -NoNewWindow -PassThru
      If ($result.ExitCode -ne 0) {
        Write-Error "Non-zero exit code: $($result.ExitCode)"
      }
    }
    If ($PSCmdlet.ShouldProcess($OutFile, "Remove")) {
      Write-Verbose "Removing $($OutFile)"
      Remove-Item $OutFile
    }
  }
}
Function InstallMsi {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Url
    ,
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutFile
    ,
    [Parameter(Position = 2)]
    [AllowEmptyCollection()]
    [string[]]$ArgumentList = @("/quiet", "/norestart")
  )
  Process {
    If (!(Test-Path $OutFile) -and $PSCmdlet.ShouldProcess($OutFile, "Download")) {
      Write-Verbose "Downloading $($OutFile)"
      Invoke-WebRequest $Url -OutFile $OutFile -UseBasicParsing
    }
    If ($PSCmdlet.ShouldProcess($OutFile, "Install")) {
      Write-Verbose "Installing $($OutFile) ($($ArgumentList -join ' '))"
      $result = Start-Process "msiexec.exe" -ArgumentList (@("/i", $OutFile) + $ArgumentList) -Wait -NoNewWindow -PassThru
      If ($result.ExitCode -ne 0) {
        Write-Error "Non-zero exit code: $($result.ExitCode)"
      }
    }
    If ($PSCmdlet.ShouldProcess($OutFile, "Remove")) {
      Write-Verbose "Removing $($OutFile)"
      Remove-Item $OutFile
    }
  }
}
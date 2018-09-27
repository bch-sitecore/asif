Function ExpandArchive {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Uri
    ,
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutFile
    ,
    [Parameter(Position = 2, Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$DestinationPath
  )
  Process {
    If (!(Test-Path $OutFile) -and $PSCmdlet.ShouldProcess($outFile, "Download")) {
      Invoke-WebRequest $Uri -OutFile $OutFile -UseBasicParsing
    }
    If ($PSCmdlet.ShouldProcess($DestinationPath, "Extract")) {
      Expand-Archive $OutFile -DestinationPath $DestinationPath -Force
    }
    If ($PSCmdlet.ShouldProcess($OutFile, "Remove")) {
      Remove-Item $OutFile
    }
  }
}
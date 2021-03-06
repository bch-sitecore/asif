Function Invoke-SqlContainedDbAuthTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "")]
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminPassword
    ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AdminUsername = "sa"
    ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServerInstance
  )
  Process {  
    If ($PSCmdlet.ShouldProcess("Enable Contained Database Authentication")) {
      Write-Verbose "Enabling Contained Database Authentication"

      $query = "sp_configure 'contained database authentication', 1;`nGO`nRECONFIGURE;`nGO"
      $invokeSqlCmdArgs = @{}
      If ($ServerInstance -ne "localhost") {
        $invokeSqlCmdArgs.Add("ServerInstance", $ServerInstance)
      }
      If ($PSCmdlet.ParameterSetName -eq "SqlLogin") {
        $invokeSqlCmdArgs.Add("Username", $AdminUsername)
        $invokeSqlCmdArgs.Add("Password", $AdminPassword)
      }
      Invoke-Sqlcmd -Query $query @invokeSqlCmdArgs
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-SqlContainedDbAuthTask -As SqlContainedDbAuth -Type Task
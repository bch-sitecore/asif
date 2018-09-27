Function Invoke-SqlContainedDbAuthTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "")]
  Param()
  Process {
    $sqlcmd = Get-ChildItem "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\" -Include "sqlcmd.exe" -Recurse |
      Select-Object -ExpandProperty FullName -First 1
  
    If ($PSCmdlet.ShouldProcess("Enable Contained Database Authentication")) {
      Write-Verbose "Enabling Contained Database Authentication"

      $query = "sp_configure 'contained database authentication', 1;`nGO`nRECONFIGURE;`nGO"
      & $sqlcmd -Q $query
      
      <#$invokeSqlCmdArgs = @{}
      If ($ServerInstance -ne "localhost") {
        $invokeSqlCmdArgs.Add("ServerInstance", $ServerInstance)
      }
      If ($PSCmdlet.ParameterSetName -eq "SqlLogin") {
        $invokeSqlCmdArgs.Add("Username", $ServerAdminUsername)
        $invokeSqlCmdArgs.Add("Password", $ServerAdminPassword)
      }
      Invoke-Sqlcmd -Query $query @invokeSqlCmdArgs#>
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-SqlContainedDbAuthTask -As SqlContainedDbAuth -Type Task
Function Invoke-DownloadSitecoreTask {
  [CmdletBinding()]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "")]
  Param(
    [Parameter(Mandatory = $true, HelpMessage = "dev.sitecore.net username")]
    [ValidateNotNullOrEmpty()]
    [Alias("Username")]
    [string]$SitecoreUsername
    ,
    [Parameter(Mandatory = $true, HelpMessage = "dev.sitecore.net password")]
    [ValidateNotNullOrEmpty()]
    [Alias("Password")]
    [string]$SitecorePassword
    ,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.Collections]$Sources
    ,
    [Parameter(Mandatory = $true, HelpMessage = "Destination path for packages")]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Destination
  )
  Process {
    # Login to dev.sitecore.net
    $loginResponse = Invoke-WebRequest "https://dev.sitecore.net/api/authorization" -Method Post -Body @{
      username = $SitecoreUsername
      password = $SitecorePassword
      rememberMe  = $true
    } -SessionVariable "scSession" -UseBasicParsing
    If ($null -eq $loginResponse -or $loginResponse.StatusCode -ne 200) {
      Write-Error "Unable to login to dev.sitecore.net with the supplied credentials"
    }

    $Sources.GetEnumerator() | ForEach-Object {
      $outFile = Join-Path $Destination -ChildPath $_.Key
      If (!(Test-Path $outFile)) {
        Invoke-WebRequest $_.Value -OutFile $outFile -WebSession $scSession -UseBasicParsing
      }
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-DownloadSitecoreTask -As DownloadSitecore -Type Task
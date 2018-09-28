Function Invoke-SitecoreXP0Task {
  [CmdletBinding(SupportsShouldProcess = $true)]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "")]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$ResourcePath
    ,
    [Parameter(Mandatory = $true)]
    [ValidateScript({ $_ -like "*.xml" })]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$LicenseFile
    ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Prefix = "xp0"
    ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SitecoreSiteName = "$($Prefix).sc"
    ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SolrServerUrl = "https://solr.sc:8983/solr"
    ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SolrServiceName = "Apache Solr 6.6.2"
    ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SqlServerInstance = "localhost"
    ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SqlAdminUsername = "sa"
    ,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SqlAdminPassword
    ,
    [Parameter(HelpMessage = "XConnect collection service")]
    [ValidateNotNullOrEmpty()]
    [string]$XConnectCollectionService = "$($Prefix).xconnect"
  )
  Process {
    $solr = (Get-Command "solr" -ErrorAction SilentlyContinue).Source
    If (!$solr) {
      Write-Error "Unable to locate solr"
    }
    $SolrPath = Split-Path (Split-Path $solr -Parent) -Parent

    # install client certificate for xconnect
    If ($PSCmdlet.ShouldProcess("Create XConnect certificate")) {
      $certParams = @{
        Path = Join-Path $ResourcePath -ChildPath "xconnect-createcert.json"
        CertificateName = "$($Prefix).xconnect_client"
      }
      Install-SitecoreConfiguration @certParams
    }

    # install solr cores for xdb
    If ($PSCmdlet.ShouldProcess("Installing SOLR cores for xDB")) {
      $solrParams = @{
        Path = Join-Path $ResourcePath -ChildPath "xconnect-solr.json"
        SolrUrl = $SolrServerUrl
        SolrRoot = $SolrPath
        SolrService = $SolrServiceName
        CorePrefix = $Prefix
      }
      Install-SitecoreConfiguration @solrParams
    }

    # deploy xconnect instance
    If ($PSCmdlet.ShouldProcess("Installing XConnect")) {
      Write-Verbose "Installing XConnect"
      $xconnectParams = @{
        Path = Join-Path $ResourcePath -ChildPath "xconnect-xp0.json"
        Package = Convert-Path (Join-Path $ResourcePath -ChildPath "*_xp0xconnect.scwdp.zip")
        LicenseFile = $LicenseFile
        Sitename = $XConnectCollectionService
        XConnectCert = $certParams.CertificateName
        SolrCorePrefix = $Prefix
        SolrURL = $SolrServerUrl
        SqlDbPrefix = $Prefix
        SqlServer = $SqlServerInstance
        SqlAdminUser = $SqlAdminUsername
        SqlAdminPassword = $SqlAdminPassword
        
        SqlCollectionUser = $SqlAdminUsername
        SqlCollectionPassword = $SqlAdminPassword
        SqlMarketingAutomationUser = $SqlAdminUsername
        SqlMarketingAutomationPassword = $SqlAdminPassword
        SqlMessagingUser = $SqlAdminUsername
        SqlMessagingPassword = $SqlAdminPassword
        SqlProcessingPoolsUser = $SqlAdminUsername
        SqlProcessingPoolsPassword = $SqlAdminPassword
        SqlReferenceDataUser = $SqlAdminUsername
        SqlReferenceDataPassword = $SqlAdminPassword
      }
      # TODO: Find out why Invoke-ManageSolrSchemaTask is failing...
      Install-SitecoreConfiguration @xconnectParams -Verbose -ErrorAction Continue
    }

    #install solr cores for sitecore
    If ($PSCmdlet.ShouldProcess("Installing SOLR cores for Sitecore")) {
      $solrParams = @{
        Path = Join-Path $ResourcePath -ChildPath "sitecore-solr.json"
        SolrUrl = $SolrServerUrl
        SolrRoot = $SolrPath
        SolrService = $SolrServiceName
        CorePrefix = $Prefix
      }
      Install-SitecoreConfiguration @solrParams
    }

    #install sitecore instance
    If ($PSCmdlet.ShouldProcess("Installing Sitecore")) {
      $sitecoreParams = @{
        Path = Join-Path $ResourcePath -ChildPath "sitecore-XP0.json"
        Package = Convert-Path (Join-Path $ResourcePath -ChildPath "*_single.scwdp.zip")
        LicenseFile = $LicenseFile
        SolrCorePrefix = $Prefix
        SolrUrl = $SolrServerUrl
        XConnectCert = $certParams.CertificateName
        Sitename = $SitecoreSiteName
        XConnectCollectionService = "https://$($XConnectCollectionService)"
        SqlDbPrefix = $Prefix
        SqlServer = $SqlServerInstance
        SqlAdminUser = $SqlAdminUsername
        SqlAdminPassword = $SqlAdminPassword
        
        SqlCoreUser = $SqlAdminUsername
        SqlCorePassword = $SqlAdminPassword
        SqlExmMasterUser = $SqlAdminUsername
        SqlExmMasterPassword = $SqlAdminPassword
        SqlFormsUser = $SqlAdminUsername
        SqlFormsPassword = $SqlAdminPassword
        SqlMarketingAutomationUser = $SqlAdminUsername
        SqlMarketingAutomationPassword = $SqlAdminPassword
        SqlMasterUser = $SqlAdminUsername
        SqlMasterPassword = $SqlAdminPassword
        SqlMessagingUser = $SqlAdminUsername
        SqlMessagingPassword = $SqlAdminPassword
        SqlProcessingPoolsUser = $SqlAdminUsername
        SqlProcessingPoolsPassword = $SqlAdminPassword
        SqlProcessingTasksUser = $SqlAdminUsername
        SqlProcessingTasksPassword = $SqlAdminPassword
        SqlReferenceDataUser = $SqlAdminUsername
        SqlReferenceDataPassword = $SqlAdminPassword
        SqlReportingUser = $SqlAdminUsername
        SqlReportingPassword = $SqlAdminPassword
        SqlWebUser = $SqlAdminUsername
        SqlWebPassword = $SqlAdminPassword
      }
      Install-SitecoreConfiguration @sitecoreParams
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-SitecoreXP0Task -As SitecoreXP0 -Type Task
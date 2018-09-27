Function Invoke-SolrTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $version = "6.6.2"
    $url = "https://archive.apache.org/dist/lucene/solr/$($version)/solr-$($version).zip"
    $outFile = Join-Path $env:TEMP -ChildPath "solr-$($version).zip"
    $installPathPattern = Join-Path $env:ProgramData -ChildPath "solr-*"
    $isInstalled = $null -ne (Get-Command "solr" -ErrorAction SilentlyContinue)

    Write-TaskInfo -Message $version -Tag "version"
    Write-TaskInfo -Message $url -Tag "url"
    Write-TaskInfo -Message $outFile -Tag "outFile"
    Write-TaskInfo -Message $isInstalled -Tag "isInstalled"
    Write-TaskInfo -Message $installPathPattern -Tag "installPathPattern"

    If (!$isInstalled) {
      Write-Verbose "Installing SOLR $($version)"

      ExpandArchive $url -OutFile $outFile -DestinationPath $env:ProgramData

      If ($PSCmdlet.ShouldProcess("`$env:PATH", "Update")) {
        $installPath = Convert-Path $installPathPattern
        Write-TaskInfo -Message $installPath -Tag "installPath"

        $solrBin = Join-Path $installPath -ChildPath "bin"
        Write-TaskInfo -Message $solrBin -Tag "solrBin"

        Write-Verbose "Adding '$($solrBin)' to `$env:PATH"
        AddPath $solrBin
      }
    } Else {
      Write-Verbose "SOLR already exists"
      Write-TaskInfo -Message "Solr $($version)" -Tag "Exists"
    }

    NewSolrConfig $installPath
    NewSolrService $installPath
  }
}
Register-SitecoreInstallExtension -Command Invoke-SolrTask -As Solr -Type Task

Function GetSolrHost {
  [CmdletBinding()]
  [OutputType([string])]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [ValidateScript({ Test-Path (Join-Path $_ -ChildPath "bin\solr.in.cmd") })]
    [string]$Path
    ,
    [Parameter(Position = 1)]
    [ValidateNotNullOrEmpty()]
    [string]$DefaultHost = "solr.local"
  )
  Process {
    $cmdFile = Join-Path $Path -ChildPath "bin\solr.in.cmd"
    $result = $DefaultHost

    If (Test-Path $cmdFile) {
      $match = (Get-Content $cmdFile) | Select-String "^set SOLR_HOST=\w+"
      If ($match) {
        $result = $match -replace "set SOLR_HOST="
      }
    }

    $result
  }
}
Function GetSolrPath {
  [OutputType([string])]
  Param()
  Process {
    $solr = Get-Command "solr" -ErrorAction SilentlyContinue
    If ($solr) {
      Split-Path (Split-Path $solr.Source -Parent) -Parent
    }
  }
}
Function GetSolrPort {
  [CmdletBinding()]
  [OutputType([int])]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [ValidateScript({ Test-Path (Join-Path $_ -ChildPath "bin\solr.in.cmd") })]
    [string]$Path
    ,
    [Parameter(Position = 1)]
    [ValidateRange(1, 65535)]
    [int]$DefaultPort = 8983
  )
  Begin {
    $cmdFile = Join-Path $Path -ChildPath "bin\solr.in.cmd"
    $result = $DefaultPort
  }
  Process {
    If (Test-Path $cmdFile) {
      $match = (Get-Content $cmdFile) | Select-String "^set SOLR_PORT=\d+"
      If ($match) {
        $result = [int]($match -replace "set SOLR_PORT=")
      }
    }
    $result
  }
}
Function NewSolrConfig {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [ValidateScript({ Test-Path (Join-Path $_ -ChildPath "bin\solr.in.cmd") })]
    [string]$Path
    ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Hostname = "solr.local"
    ,
    [Parameter()]
    [ValidateRange(1, 65535)]
    [int]$Port = 8983
  )
  Process {
    Write-TaskInfo -Message $Path -Tag "NewSolrConfig.Path"
    Write-TaskInfo -Message $Hostname -Tag "NewSolrConfig.Hostname"
    Write-TaskInfo -Message $Port -Tag "NewSolrConfig.Port"

    $binPath = Join-Path $Path -ChildPath "bin"
    $serverPath = Join-Path $Path -ChildPath "server"
    $friendlyName = "Apache Solr"

    $cmdFile = Join-Path $binPath -ChildPath "solr.in.cmd"
    $cmdFileOrig = Join-Path $binPath -ChildPath "solr.in.cmd.orig"

    $certFile = Join-Path $serverPath -ChildPath "etc\solr-ssl.keystore.pfx"
    $certPassword = NewRandomPassword -Length 12

    Write-TaskInfo -Message $binPath -Tag "NewSolrConfig.binPath"
    Write-TaskInfo -Message $serverPath -Tag "NewSolrConfig.serverPath"
    Write-TaskInfo -Message $friendlyName -Tag "NewSolrConfig.friendlyName"
    Write-TaskInfo -Message $cmdFile -Tag "NewSolrConfig.cmdFile"
    Write-TaskInfo -Message $cmdFileOrig -Tag "NewSolrConfig.cmdFileOrig"
    Write-TaskInfo -Message $certFile -Tag "NewSolrConfig.certFile"
    Write-TaskInfo -Message $certPassword -Tag "NewSolrConfig.certPassword"

    If ((Test-Path $certFile) -and $PSCmdlet.ShouldProcess($certFile, "Remove")) {
      Write-Verbose "Removing '$(certFile)'"
      Remove-Item $certFile
    }
    If ($PSCmdlet.ShouldProcess($certFile, "Create")) {
      Write-Verbose "Creating SOLR cert '$($certFile)'"
      $cert = GetCert -ByFriendlyName $friendlyName -CertStoreLocation "Cert:\LocalMachine\Root"
      If (!$cert) {
        $cert = GetCert -ByFriendlyName $friendlyName -CertStoreLocation "Cert:\LocalMachine\My"
        If (!$cert) {
          $cert = New-SelfSignedCertificate -CertStoreLocation "Cert:\LocalMachine\My" `
            -DnsName $Hostname -FriendlyName $friendlyName -NotAfter (Get-Date).AddYears(2)
          Write-Verbose "  created w/ Thumbprint $($cert.Thumbprint)"
          Write-TaskInfo -Message $cert.Thumbprint -Tag "NewSolrConfig.cert.Thumbprint"
        } Else {
          Write-Verbose "  found w/ Thumbprint $($cert.Thumbprint)"
          Write-TaskInfo -Message $cert.Thumbprint -Tag "NewSolrConfig.cert.Thumbprint"
        }

        $storeName = [System.Security.Cryptography.X509Certificates.StoreName]::Root
        $storeLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
        $openFlags = [System.Security.Cryptography.X509Certificates.OpenFlags]::MaxAllowed
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store $storeName, $storeLocation
        $store.Open($openFlags)
        $store.Add($cert)
        $store.Close()
        Write-Verbose "  added to Cert:\LocalMachine\Root"
      } Else {
        Write-Verbose "  exists w/ Thumbprint $($cert.Thumbprint)"
        Write-TaskInfo -Message $cert.Thumbprint -Tag "NewSolrConfig.cert.Thumbprint"
      }

      Write-Verbose "Exporting certificate to '$($certFile)' w/ password $($certPassword)"
      Export-PfxCertificate -Cert $cert -FilePath $certFile `
        -Password (ConvertTo-SecureString $certPassword -AsPlainText -Force) | Out-Null
    }
    If (!(Test-Path $cmdFileOrig) -and $PSCmdlet.ShouldProcess($cmdFile, "Backup")) {
      Write-Verbose "Backing up $($cmdFile) to $($cmdFileOrig)"
      Move-Item $cmdFile -Destination $cmdFileOrig
    }
    If ($PSCmdlet.ShouldProcess($cmdFile, "Write")) {
      Write-Verbose "Writing config to $($cmdFile)"
      $config = @(
        "REM",
        "REM Generated on $(Get-Date -Format G) by Unattended.SIF",
        "REM",
        "set SOLR_HOST=$($Hostname)",
        "set SOLR_PORT=$($Port)",
        "set SOLR_SSL_KEY_STORE=etc/$(Split-Path $certFile -Leaf)",
        "set SOLR_SSL_KEY_STORE_PASSWORD=$($certPassword)",
        "set SOLR_SSL_KEY_STORE_TYPE=PKCS12",
        "set SOLR_SSL_TRUST_STORE=etc/$(Split-Path $certFile -Leaf)",
        "set SOLR_SSL_TRUST_STORE_PASSWORD=$($certPassword)",
        "set SOLR_SSL_TRUST_STORE_TYPE=PKCS12",
        "set SOLR_OPTS=%SOLR_OPTS% -Dsolr.log.muteconsole"
      )
      $config | ForEach-Object -Begin { $line = 0 } { $line++; "{0}: {1}" -f ([string]$line).PadLeft(3), $_ } | Write-Verbose
      $config | Set-Content $cmdFile
    }
    If (($Hostname -ne "localhost" -and $Hostname -ne $env:COMPUTERNAME) -and $PSCmdlet.ShouldProcess("HOSTS", "Update")) {
      Write-Verbose "Adding $($Hostname) to HOSTS file"
      AddHostsEntry $Hostname "127.0.0.1"
    }
  }
}
Function NewSolrService {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [ValidateScript({ Test-Path (Join-Path $_ -ChildPath "bin\solr.in.cmd") })]
    [string]$Path
  )
  Process {
    Write-TaskInfo -Message $Path -Tag "NewSolrService.Path"

    $binPath = Join-Path $Path -ChildPath "bin"
    $serviceName = "Apache Solr 6.6.2"
    $serviceAccount = "NT AUTHORITY\NetworkService"
    $serviceHost = GetSolrHost $Path
    $servicePort = GetSolrPort $Path
    $tmpPath = Join-Path $Path -ChildPath "server\tmp" # aka -Djava.io.tmpdir=
    $logsPath = Join-Path $Path -ChildPath "server\logs"

    $nssm = (Get-Command "nssm.exe" -ErrorAction SilentlyContinue).Source
    If (!$nssm) {
      Write-Error "NSSM must be installed and discoverable via `$env:PATH (run Install-NSSM first)"
    }

    $isInstalled = $null -ne (Get-Service $serviceName -ErrorAction SilentlyContinue)
  
    Write-TaskInfo -Message $binPath -Tag "NewSolrService.binPath"
    Write-TaskInfo -Message $serviceName -Tag "NewSolrService.serviceName"
    Write-TaskInfo -Message $serviceAccount -Tag "NewSolrService.serviceAccount"
    Write-TaskInfo -Message $serviceHost -Tag "NewSolrService.serviceHost"
    Write-TaskInfo -Message $servicePort -Tag "NewSolrService.servicePort"
    Write-TaskInfo -Message $tmpPath -Tag "NewSolrService.tmpPath"
    Write-TaskInfo -Message $logsPath -Tag "NewSolrService.logsPath"
    Write-TaskInfo -Message $nssm -Tag "NewSolrService.nssm"
  
    If (!$isInstalled) {
      Write-Verbose "Installing Solr Service"
      If ($PSCmdlet.ShouldProcess($serviceName, "Install service")) {

        $serviceCmd = "`"`"$(Join-Path $binPath -ChildPath 'solr.cmd')`"`" start -port $($servicePort) -foreground -verbose"

        & $nssm install $serviceName "cmd.exe" "/C $($serviceCmd) < nul" | Out-Null
        & $nssm set $serviceName Description "Apache Solr 6.6.2 (https://$($serviceHost):$($servicePort)/solr/#)"
        & $nssm set $serviceName AppDirectory $tmpPath
        & $nssm set $serviceName AppStdoutCreationDisposition 2
        & $nssm set $serviceName AppStdout (Join-Path $logsPath -ChildPath "nssm.log")
        & $nssm set $serviceName AppStderrCreationDisposition 2
        & $nssm set $serviceName AppStderr (Join-Path $logsPath -ChildPath "nssm.log")
        & $nssm set $serviceName AppRotateFiles 1
        & $nssm set $serviceName AppRotateBytes 1048576
        & $nssm set $serviceName AppStopMethodConsole 15000
        & $nssm set $serviceName AppExit "Default" "Exit"
        & $nssm set $serviceName Start "SERVICE_AUTO_START"

        # Run service under $serviceAccount
        & sc.exe config $serviceName obj= $serviceAccount

        # Give serviceAccount Read/execute access to entire directory
        # (ObjectInherit)(ContainerInherit)Read Execute
        & icacls.exe $Path /grant "$($serviceAccount):(OI)(CI)RX"

        @($tmpPath, $logsPath) | ForEach-Object {
          If (!(Test-Path $_)) {
            New-Item $_ -ItemType Directory | Out-Null
          }
          & icacls.exe $_ /grant "$($serviceAccount):(OI)(CI)M"
        }

      }
    } Else {
      Write-Verbose "Solr Service already exists"
      Write-TaskInfo -Message "Solr Service" -Tag "Exists"
    }
  }
}
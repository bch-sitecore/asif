Function Invoke-SqlServerDeveloperTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminPassword
  )
  Process {
    Write-TaskInfo -Message $AdminPassword -Tag "AdminPassword"

    $boxOutFile = Join-Path $env:TEMP -ChildPath "SQLServer2017-DEV-x64-ENU.box"
    $boxUrl = "https://go.microsoft.com/fwlink/?linkid=840944"
    $exeOutFile = Join-Path $env:TEMP -ChildPath "SQLServer2017-DEV-x64-ENU.exe"
    $exeUrl = "https://go.microsoft.com/fwlink/?linkid=840945"
    $setupPath = Join-Path $env:TEMP -ChildPath "sqlsetup"
    $setupExe = Join-Path $setupPath -ChildPath "setup.exe"

    $isInstalled = Test-Path "HKLM:\Software\Microsoft\Microsoft SQL Server\MSSQL*.MSSQLSERVER\MSSQLServer"

    Write-TaskInfo -Message $boxOutFile -Tag "boxOutFile"
    Write-TaskInfo -Message $boxUrl -Tag "boxUrl"
    Write-TaskInfo -Message $exeOutFile -Tag "exeOutFile"
    Write-TaskInfo -Message $exeUrl -Tag "exeUrl"
    Write-TaskInfo -Message $setupPath -Tag "setupPath"
    Write-TaskInfo -Message $setupExe -Tag "setupExe"
    Write-TaskInfo -Message $isInstalled -Tag "isInstalled"

    If (!$isInstalled) {
      Write-Verbose "Installing SQL Server Developer"

      If (!(Test-Path $boxOutFile) -and $PSCmdlet.ShouldProcess($boxOutFile, "Download")) {
        Write-Verbose "Downloading $($boxOutFile)"
        Invoke-WebRequest $boxUrl -OutFile $boxOutFile -UseBasicParsing
      }
      If (!(Test-Path $exeOutFile) -and $PSCmdlet.ShouldProcess($exeOutFile, "Download")) {
        Write-Verbose "Downloading $($exeOutFile)"
        Invoke-WebRequest $exeUrl -OutFile $exeOutFile -UseBasicParsing
      }
      If (!(Test-Path $setupPath) -and $PSCmdlet.ShouldProcess($setupPath, "Extract")) {
        Write-Verbose "Extracting $($exeOutFile) to $($setupPath)"
        $result = Start-Process $exeOutFile -ArgumentList "/qs", "/x:$($setupPath)" -Wait -PassThru
        If ($result.ExitCode -ne 0) {
          Write-Error "Non-zero exit code: $($result.ExitCode)"
        }
      }
      If ($PSCmdlet.ShouldProcess($boxOutFile, "Remove")) {
        Write-Verbose "Removing $($boxOutFile)"
        Remove-Item $boxOutFile
      }
      If ($PSCmdlet.ShouldProcess($exeOutFile, "Remove")) {
        Write-Verbose "Removing $($exeOutFile)"
        Remove-Item $exeOutFile
      }
      If ($PSCmdlet.ShouldProcess($setupExe, "Install")) {
        Write-Verbose "Running installer $($setupExe)"
        & $setupExe /q /ACTION=Install `
          /INSTANCENAME=MSSQLSERVER `
          /FEATURES=SQLEngine `
          /UPDATEENABLED=0 `
          /SQLSVCACCOUNT='NT AUTHORITY\System' `
          /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' `
          /TCPENABLED=1 `
          /NPENABLED=0 `
          /IACCEPTSQLSERVERLICENSETERMS
      }
      If ($PSCmdlet.ShouldProcess($setupPath, "Remove")) {
        Write-Verbose "Removing $($setupPath)"
        Remove-Item $setupPath -Recurse
      }
    } Else {
      Write-Verbose "SQL Server Developer already installed"
    }
    If ($PSCmdlet.ShouldProcess("MSSQLSERVER", "Configure")) {
      Write-Verbose "Configuring SQL Server Developer"

      Write-Verbose "Stopping MSSQLSERVER service"
      Stop-Service "MSSQLSERVER"

      Write-Verbose "Modifying registry"
      $keyRoot = (Convert-Path "HKLM:\Software\Microsoft\Microsoft SQL Server\MSSQL*.MSSQLSERVER\MSSQLServer") -replace "HKEY_LOCAL_MACHINE", "HKLM:"
      @(
        @{
            Path = "$($keyRoot)\SuperSocketNetLib\TCP\IPAll"
            Name = "TCPDynamicPorts"
            Value = ""
        },
        @{
            Path = "$($keyRoot)\SuperSocketNetLib\TCP\IPAll"
            Name = "TCPPort"
            Value = 1433
        },
        @{
            Path = $keyRoot
            Name = "LoginMode"
            Value = 2
        }
      ) | ForEach-Object {
        $reg = $_

        Write-Verbose "[$($reg.Path)]`n$($reg.Name)=$($reg.Value)"
        Set-ItemProperty $reg.Path -Name $reg.Name -Value $reg.Value
      }

      Write-Verbose "Starting MSSQLSERVER service"
      Start-Service "MSSQLSERVER"
    }
    If ($PSCmdlet.ShouldProcess($AdminPassword, "Set SA Password")) {
      $sqlcmd = Get-ChildItem 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\' -Include 'sqlcmd.exe' -Recurse |
        Select-Object -ExpandProperty FullName -First 1
      $sanitizedPassword = $AdminPassword -replace "'", "''"
      & $sqlcmd -Q "ALTER LOGIN sa with password='$($sanitizedPassword)';`nGO`nALTER LOGIN sa ENABLE;`nGO"
    }
    If ($PSCmdlet.ShouldProcess("PSModule:SQLPS", "Remove")) {
      # SQLPS comes with SQL.
      # Its since been deprecated and should no longer be used.
      # SqlServer is the only module now being maintained
      Get-InstalledModule "SQLPS" -AllVersions -ErrorAction SilentlyContinue | Remove-Module -Force
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-SqlServerDeveloperTask -As SqlServerDeveloper -Type Task
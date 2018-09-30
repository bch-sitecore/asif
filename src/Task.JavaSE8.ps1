Function Invoke-JavaSE8Task {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $url = GetJre8Url
    If (!$url) {
      Write-Error "Unable to get URL of Java SE 8"
    }

    $arch = ("x86","x64")[[System.Environment]::Is64BitOperatingSystem]
    $fileInfo = GetJre8FileInfo | Where-Object { $_.arch -eq $arch }
    $outFile = Join-Path $env:TEMP -ChildPath $fileInfo.filename
    $isInstalled = Test-Path "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment"

    Write-TaskInfo -Message $url -Tag "url"
    Write-TaskInfo -Message $arch -Tag "arch"
    Write-TaskInfo -Message $outFile -Tag "outFile"
    Write-TaskInfo -Message $isInstalled -Tag "isInstalled"

    If (!$isInstalled) {
      Write-Verbose "Installing Java SE 8"

      If (!(Test-Path $outFile) -and $PSCmdlet.ShouldProcess($outFile, "Download")) {
        Write-Verbose "Downloading $($outFile)"
        Invoke-RestMethod $Url -Method Post -Body @{ "$($fileInfo.cookiename)" = "on" } -SessionVariable "jre8Session" | Out-Null
        $cookie = New-Object System.Net.Cookie -Property @{
          Name = "oraclelicense"
          Value = "accept-securebackup-cookie"
          Domain = ".oracle.com"
        }
        $jre8Session.Cookies.Add($cookie)
        Invoke-WebRequest $fileInfo.filepath -OutFile $outFile -WebSession $jre8Session -UseBasicParsing
      }
      If ($PSCmdlet.ShouldProcess($outFile, "Install")) {
        $installArgs = @(
          "REBOOT=Disable"
          "STATIC=Enable"
          "WEB_JAVA=Disable"
          "WEB_ANALYTICS=Disable"
          "/s"
        )
        $result = Start-Process $outFile -ArgumentList $installArgs -Wait -PassThru
        If ($result.ExitCode -ne 0) {
          Write-Error "Non-zero exit code, $($result.ExitCode)"
        }

        $jreVersion = Get-ChildItem "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment" | Select-Object -ExpandProperty pschildname -Last 1
        Write-TaskInfo -Message $jreVersion -Tag "Version"

        $env:JAVA_HOME = Convert-Path (Join-Path $env:ProgramFiles -ChildPath "Java\jre*")
        [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $env:JAVA_HOME, [System.EnvironmentVariableTarget]::Machine)
        Write-TaskInfo -Message $env:JAVA_HOME -Tag "env:JAVA_HOME"

        $javaBin = Join-Path $env:JAVA_HOME -ChildPath "bin"
        Write-TaskInfo -Message $javaBin -Tag "javaBin"
        AddPath $javaBin
      }
    } Else {
      Write-Verbose "Java SE 8 already exists"
      Write-TaskInfo -Message "Java SE 8" -Tag "Exists"
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-JavaSE8Task -As JavaSE8 -Type Task

Function GetJre8Url {
  Begin {
    $baseUrl = "https://www.oracle.com"
    $url = "$($baseUrl)/technetwork/java/javase/downloads/index.html"
  }
  Process {
    $jdk8 = (Invoke-WebRequest $url -UseBasicParsing).Content -split "[\r\n]" | Select-String "/java/javase/downloads/jre8-"
    If ($jdk8 -match "href=`"([^`"]+)`"") {
      # e.g. https://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html
      "$($baseUrl)$($Matches[1])"
    }
  }
}

Function GetJre8FileInfo {
  Begin {
    $url = GetJre8Url
    If (!$url) {
      Write-Error "Unable to get URL of JRE8"
    }

    $pattern = "downloads\['(?<cookieName>[^']+)'\]\['files'\]\['[^']+-windows-(?:x64|i586)\.exe'\] = (?<jso>\{.*?\})"
    $results = @()
  }
  Process {
    (Invoke-WebRequest $url -UseBasicParsing).Content -split "[\r\n]" | Select-String $pattern | ForEach-Object {
      If ($_ -match $pattern) {
        $result = $Matches.jso | ConvertFrom-Json
        $result | Add-Member NoteProperty "cookiename" $Matches.cookieName
        $result | Add-Member NoteProperty "arch" ("x86","x64")[$result.filepath -like "*-x64.exe"]
        $result | Add-Member NoteProperty "filename" (Split-Path $result.filepath -Leaf)
        $results += $result
      }
    }
  }
  End {
    <#
      e.g.
        title      : Windows x86 Offline
        size       : 61.55 MB
        filepath   : http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jre-8u181-windows-i586.exe
        MD5        : b97be9584268202f2fba665505f7828e
        SHA256     : 9e5e6a1c5d26d93454751e65486f728233fdac3b50ff763f6709fb87dd960ce5
        cookiename : jre-8u181-oth-JPR
        arch       : x86
        filename   : jre-8u181-windows-i586.exe

        title      : Windows x64
        size       : 68.47 MB
        filepath   : http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jre-8u181-windows-x64.exe
        MD5        : 7f125bd071f2f83d91a8146bcb48bda5
        SHA256     : cd2f756133d59525869acb605a54efd132fcd7eaf53e2ec040d92ef40a2ea60a
        cookiename : jre-8u181-oth-JPR
        arch       : x64
        filename   : jre-8u181-windows-x64.exe
    #>
    $results
  }
}
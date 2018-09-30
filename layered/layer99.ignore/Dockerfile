# escape=`
ARG BASEIMAGE
FROM ${BASEIMAGE}
SHELL ["powershell", "-Command", "$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue';"]

ENV SIFRepoName="SitecoreGallery" `
    SIFModuleName="SitecoreInstallFramework"

RUN Uninstall-Module $env:SIFModuleName -Force ; `
    Unregister-PSRepository $env:SIFRepoName
    
WORKDIR /
RUN Remove-Item c:\resourcefiles -Recurse
#RUN Remove-Item C:\inetpub\wwwroot\*\App_Data\license.xml

ARG service_monitor="https://dotnetbinaries.blob.core.windows.net/servicemonitor/2.0.1.3/ServiceMonitor.exe"
RUN Invoke-WebRequest $env:service_monitor -OutFile "C:\ServiceMonitor.exe" -UseBasicParsing
ENTRYPOINT ["C:\\ServiceMonitor.exe", "w3svc"]
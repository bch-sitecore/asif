# escape=`
ARG BASEIMAGE
FROM ${BASEIMAGE}
SHELL ["powershell", "-Command", "$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue';"]

ENV SIFRepoName="SitecoreGallery" `
    SIFRepoLocation="https://sitecore.myget.org/F/sc-powershell/api/v2" `
    SIFModuleName="SitecoreInstallFramework"
RUN Install-PackageProvider -Name "NuGet" -Force ; `
    Register-PSRepository $env:SIFRepoName -SourceLocation $env:SIFRepoLocation -InstallationPolicy Trusted ; `
    Install-Module $env:SIFModuleName -Repository $env:SIFRepoName

COPY ./dist /install
WORKDIR /install
RUN Install-SitecoreConfiguration -Path .\sitecore-onebox.json -Name $env:USERNAME

ENTRYPOINT ["powershell"]
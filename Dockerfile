# escape=`
ARG BASEIMAGE
FROM ${BASEIMAGE}
SHELL ["powershell", "-Command", "$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue';"]

# ARG SitecoreDevUsername
# ARG SitecoreDevPassword
COPY . /
WORKDIR /resourcefiles
RUN Install-SitecoreConfiguration `
      -Path .\sitecore-onebox.json

ENTRYPOINT ["powershell"]
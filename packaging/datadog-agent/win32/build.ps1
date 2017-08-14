# Variables
if (Test-Path variable:global:$env:BUILD_NUMBER) {
	$build_num = $env:BUILD_NUMBER
} else {
	$build_num = '0'
}

$version = "$(python -c "from config import get_version; print get_version()").$build_num"

# Remove old artifacts
rm -r build/*
rm -r dist/*

# Build the agent.exe service
python setup.py py2exe
mkdir packaging\datadog-agent\win32\install_files\Microsoft.VC90.CRT

cp dist\*.* packaging\datadog-agent\win32\install_files\files
cp dist\Microsoft.VC90.CRT\* packaging\datadog-agent\win32\install_files\Microsoft.VC90.CRT\

# Change to the packaging directory
cd packaging\datadog-agent\win32

# Copy checks.d files into the install_files
mkdir install_files\checks.d
cp ..\..\..\checks.d\* install_files\checks.d

# Copy the conf.d files into the install_files
mkdir install_files\conf.d
cp ..\..\..\conf.d\* install_files\conf.d

# Copy JMX Fetch into the install_files
cp -R ..\..\..\dist\jmxfetch install_files\files\jmxfetch

# Copy JMX Fetch into the install_files
cp -R ..\..\..\dist\gohai install_files\files\gohai

# Move the images needed for the gui
cp -R install_files\guidata install_files\files

# Copy the license file
cp ..\..\..\LICENSE.rtf install_files\license.rtf

#Copy the Status template
cp ..\..\..\win32\status.html install_files\files

## Generate the CLI installer with WiX

    # Generate fragments for the files in checks.d, conf.d and pup
    heat dir install_files\files -gg -dr INSTALLDIR -t wix\files.xslt -var var.InstallFilesBins -cg files -o wix\files.wxs
    heat dir install_files\checks.d -gg -dr INSTALLDIR -var var.InstallFilesChecksD -cg checks.d -o wix\checksd.wxs
    heat dir install_files\conf.d -gg -dr APPLIDATIONDATADIRECTORY -t wix\confd.xslt -var var.InstallFilesConfD -cg conf.d -o wix\confd.wxs

    # Create .wixobj files from agent.wxs, confd.wxs, checksd.wxs
    $opts = '-dInstallFiles=install_files', '-dWixRoot=wix', '-dInstallFilesChecksD=install_files\checks.d', '-dInstallFilesConfD=install_files\conf.d', '-dInstallFilesBins=install_files\files', "-dAgentVersion=$version"
    candle $opts wix\agent.wxs wix\checksd.wxs wix\confd.wxs wix\files.wxs -ext WixUIExtension -ext WixUtilExtension

    # Light to create the msi
    light agent.wixobj checksd.wixobj confd.wixobj files.wixobj -o ..\..\..\build\ddagent.msi -ext WixUIExtension -ext WixUtilExtension

# Clean up
rm *wixobj*
rm -r install_files\files\guidata
rm -r install_files\files\jmxfetch
rm -r install_files\files\gohai
rm install_files\files\*.*
rm -r install_files\conf.d
rm -r install_files\checks.d
rm -r install_files\Microsoft.VC90.CRT


# Move back to the root workspace
cd ..\..\..\

# Sign the installers
# TODO

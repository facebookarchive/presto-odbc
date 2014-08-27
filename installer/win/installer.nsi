!define APPNAME "Presto ODBC Driver (64-bit)"
!define DESCRIPTION "Presto ODBC Driver (64-bit)"

#installer files
!define LICENSE_FILE "..\..\LICENSE"
!define PRESTO_DLL "..\..\presto.dll"
!define LIBCURL_DLL "..\..\libcurl.dll"

# These three must be integers
!define VERSIONMAJOR 1
!define VERSIONMINOR 1
!define VERSIONBUILD 1

# These will be displayed by the "Click here for support information" link in "Add/Remove Programs"
# It is possible to use "mailto:" links in here to open the email client
!define HELPURL "https://github.com/prestodb/presto-odbc" # "Support Information" link
!define UPDATEURL "https://github.com/prestodb/presto-odbc" # "Product Updates" link
!define ABOUTURL "https://github.com/prestodb/presto-odbc" # "Publisher" link

# This is the size (in kB) of all the files copied
!define INSTALLSIZE 3370
 
RequestExecutionLevel admin ;Require admin rights on NT6+ (When UAC is turned on)
 
InstallDir "C:\temp"
 
# rtf or txt file - remember if it is txt, it must be in the DOS text format (\r\n)
LicenseData "${LICENSE_FILE}"

# This will be in the installer/uninstaller's title bar
Name "${APPNAME}"
outFile "presto-installer-64.exe"
 
!include LogicLib.nsh
 
# Just three pages - license agreement, install location, and installation
page license
page directory
Page instfiles
 
!macro VerifyUserIsAdmin
UserInfo::GetAccountType
pop $0
${If} $0 != "admin" ;Require admin rights on NT4+
        messageBox mb_iconstop "Administrator rights required!"
        setErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
        quit
${EndIf}
!macroend
 
function .onInit
	setShellVarContext all
	SetRegView 64
	!insertmacro VerifyUserIsAdmin
functionEnd
 
section "install"
	setOutPath $INSTDIR

	# Files added here should be removed by the uninstaller (see section "uninstall")
	file "${PRESTO_DLL}"
	file "${LIBCURL_DLL}"
 
	# Uninstaller - See function un.onInit and section "uninstall" for configuration
	writeUninstaller "$INSTDIR\uninstall.exe"
 
	# Registry keys for the driver
	WriteRegStr HKEY_LOCAL_MACHINE "Software\ODBC\ODBCINST.INI\ODBC Drivers" "Presto ODBC Driver" "Installed"
	WriteRegStr HKEY_LOCAL_MACHINE "Software\ODBC\ODBCINST.INI\Presto ODBC Driver" "Setup" "$INSTDIR\presto.dll"
	WriteRegStr HKEY_LOCAL_MACHINE "Software\ODBC\ODBCINST.INI\Presto ODBC Driver" "Driver" "$INSTDIR\presto.dll"
	WriteRegDWORD HKEY_LOCAL_MACHINE "Software\ODBC\ODBCINST.INI\Presto ODBC Driver" "UsageCount" 1
sectionEnd
 
# Uninstaller
function un.onInit
	SetShellVarContext all
 	SetRegView 64
	#Verify the uninstaller - last chance to back out
	MessageBox MB_OKCANCEL "Permanently remove ${APPNAME}?" IDOK next
		Abort
	next:
	!insertmacro VerifyUserIsAdmin
functionEnd
 
section "uninstall"
	# Remove files
	delete $INSTDIR\"${PRESTO_DLL}"
	delete $INSTDIR\"${LIBCURL_DLL}"
	delete $INSTDIR\*.log
	delete $INSTDIR\uninstall.exe
 
	# Try to remove the install directory - this will only happen if it is empty
	rmDir $INSTDIR
 
	# Remove driver info from the registry
	DeleteRegValue HKLM "Software\ODBC\ODBCINST.INI\ODBC Drivers" "Presto ODBC Driver"
	DeleteRegKey HKLM "Software\ODBC\ODBCINST.INI\Presto ODBC Driver"
	
sectionEnd
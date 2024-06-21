echo \" <<'RUN_AS_BATCH' >/dev/null ">NUL "\" \`" <#"
@ECHO OFF
REM LICENSE CLAUSES HERE
REM ----------------------------------------------------------------------------




REM ############################################################################
REM # Windows BATCH Codes                                                      #
REM ############################################################################
where /q powershell
if errorlevel 1 (
        echo "ERROR: missing powershell facility."
        exit /b 1
)

copy /Y "%~nx0" "%~n0.ps1" >nul
timeout /t 1 /nobreak >nul
powershell -executionpolicy remotesigned -Command "& '.\%~n0.ps1' %*"
start /b "" cmd /c del "%~f0" & exit /b %errorcode%
REM ############################################################################
REM # Windows BATCH Codes                                                      #
REM ############################################################################
RUN_AS_BATCH
#> | Out-Null




echo \" <<'RUN_AS_POWERSHELL' >/dev/null # " | Out-Null
################################################################################
# Windows POWERSHELL Codes                                                     #
################################################################################
. "${env:LIBS_HESTIA}\hestiaI18N\Get_Languages_List.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-Already-Latest-Version.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-All-Components-Description.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-All-Components-Title.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-Bin-Components-Description.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-Bin-Components-Title.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-Docs-Components-Description.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-Docs-Components-Title.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-Config-Components-Description.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-Config-Components-Title.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-Lib-Components-Description.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-Lib-Components-Title.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-Main-Components-Description.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-Main-Components-Title.sh.ps1"
. "${env:LIBS_HESTIA}\hestiaI18N\Translate-Only-Install-On-Windows.sh.ps1"
################################################################################
# Windows POWERSHELL Codes                                                     #
################################################################################
return
<#
RUN_AS_POWERSHELL




################################################################################
# Unix Main Codes                                                              #
################################################################################
. "${LIBS_HESTIA}/hestiaI18N/Get_Languages_List.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-Already-Latest-Version.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-All-Components-Description.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-All-Components-Title.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-Bin-Components-Description.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-Bin-Components-Title.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-Docs-Components-Description.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-Docs-Components-Title.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-Config-Components-Description.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-Config-Components-Title.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-Lib-Components-Description.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-Lib-Components-Title.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-Main-Components-Description.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-Main-Components-Title.sh.ps1"
. "${LIBS_HESTIA}/hestiaI18N/Translate-Only-Install-On-Windows.sh.ps1"
################################################################################
# Unix Main Codes                                                              #
################################################################################
return 0
#>
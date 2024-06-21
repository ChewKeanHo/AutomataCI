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
function hestiaI18N-Translate-Already-Latest-Version() {
	param(
		[string]$___locale
	)


	# execute
	switch ("${___locale}") {
	"zh-hans" {
		# 简体中文
		return "您已经有同样或是最新的版本了。那就不需要任何另外加工吧。"
	} default {
		# fallback to default english
		return "You have the same/latest version. No further action is required."
	}}


	# report status
	return 0
}
################################################################################
# Windows POWERSHELL Codes                                                     #
################################################################################
return
<#
RUN_AS_POWERSHELL




################################################################################
# Unix Main Codes                                                              #
################################################################################
hestiaI18N_Translate_Already_Latest_Version() {
        #___locale="$1"


        # execute
        case "$1" in
        zh-hans)
                # 简体中文
                printf -- "%b" "您已经有同样或是最新的版本了。那就不需要任何另外加工吧。"
                ;;
        *)
                # fallback to default english
                printf -- "%b" "You have the same/latest version. No further action is required."
        esac


        # report status
        return 0
}
################################################################################
# Unix Main Codes                                                              #
################################################################################
return 0
#>

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
function hestiaI18N-Translate-Only-Install-On-Windows() {
	param(
		[string]$___locale,
		[string]$___arch
	)


	# execute
	switch (${___locale}) {
	"zh-hans" {
		# 简体中文
		switch ("${___arch}") {
		"32" {
			return @"
真遗憾。您只能在32位微软Windows操作系统里安装。
"@
		} "64" {
			return @"
真遗憾。您只能在64位微软Windows操作系统里安装。
"@
		} "amd64" {
			return @"
真遗憾。您只能在amd64型芯片的微软Windows操作系统里安装。
"@
		} "arm64" {
			return @"
真遗憾。您只能在arm64型芯片的微软Windows操作系统里安装。
"@
		} "i386" {
			return @"
真遗憾。您只能在i386型芯片的微软Windows操作系统里安装。
"@
		} "arm" {
			return @"
真遗憾。您只能在arm型芯片的微软Windows操作系统里安装。
"@
		} default {
			return @"
真遗憾。您只能在微软Windows操作系统里安装。
"@
		}}
	} default {
		# fallback to default english
		switch ("${___arch}") {
		"32" {
			return @"
Unfortunately, you can only install this in a 32-bits Microsoft Windows operating system.
"@
		} "64" {
			return @"
Unfortunately, you can only install this in a 64-bits Microsoft Windows operating system.
"@
		} "amd64" {
			return @"
Unfortunately, you can only install this in an amd64 Microsoft Windows operating system.
"@
		} "arm64" {
			return @"
Unfortunately, you can only install this in an arm64 Microsoft Windows operating system.
"@
		} "i386" {
			return @"
Unfortunately, you can only install this in an i386 Microsoft Windows operating system.
"@
		} "arm" {
			return @"
Unfortunately, you can only install this in an arm Microsoft Windows operating system.
"@
		} default {
			return @"
Unfortunately, you can only install this in a Microsoft Windows operating system.
"@
		}}
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
hestiaI18N_Translate_Only_Install_On_Windows() {
        #___locale="$1"
        #___arch="$2"


        # execute
        case "$1" in
        zh-hans)
                # 简体中文
                case "$2" in
                32)
                        printf -- "%b" "\
真遗憾。您只能在32位微软Windows操作系统里安装。"
                        ;;
                64)
                        printf -- "%b" "\
真遗憾。您只能在64位微软Windows操作系统里安装。"
                        ;;
                amd64)
                        printf -- "%b" "\
真遗憾。您只能在amd64型芯片的微软Windows操作系统里安装。"
                        ;;
                arm64)
                        printf -- "%b" "\
真遗憾。您只能在arm64型芯片的微软Windows操作系统里安装。"
                        ;;
                i386)
                        printf -- "%b" "\
真遗憾。您只能在i386型芯片的微软Windows操作系统里安装。"
                        ;;
                arm)
                        printf -- "%b" "\
真遗憾。您只能在arm型芯片的微软Windows操作系统里安装。"
                        ;;
                *)
                        printf -- "%b" "\
真遗憾。您只能在微软Windows操作系统里安装。"
                        ;;
                esac
                ;;
        *)
                # fallback to default english
                case "$2" in
                32)
                        printf -- "%b" "\
Unfortunately, you can only install this in a 32-bits Microsoft Windows operating system."
                        ;;
                64)
                        printf -- "%b" "\
Unfortunately, you can only install this in a 64-bits Microsoft Windows operating system."
                        ;;
                amd64)
                        printf -- "%b" "\
Unfortunately, you can only install this in an amd64 Microsoft Windows operating system."
                        ;;
                arm64)
                        printf -- "%b" "\
Unfortunately, you can only install this in an arm64 Microsoft Windows operating system."
                        ;;
                i386)
                        printf -- "%b" "\
Unfortunately, you can only install this in an i386 Microsoft Windows operating system."
                        ;;
                arm)
                        printf -- "%b" "\
Unfortunately, you can only install this in an arm Microsoft Windows operating system."
                        ;;
                *)
                        printf -- "%b" "\
Unfortunately, you can only install this in a Microsoft Windows operating system."
                        ;;
                esac
        esac


        # report status
        return 0
}
################################################################################
# Unix Main Codes                                                              #
################################################################################
return 0
#>

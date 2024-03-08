echo \" <<'RUN_AS_BATCH' >/dev/null ">NUL "\" \`" <#"
@ECHO OFF
REM LICENSE CLAUSES HERE
REM ----------------------------------------------------------------------------




REM ############################################################################
REM # Windows BATCH Codes                                                      #
REM ############################################################################
echo "[ ERROR ] --> powershell.exe !!!"
exit /b 1
REM ############################################################################
REM # Windows BATCH Codes                                                      #
REM ############################################################################
RUN_AS_BATCH
#> | Out-Null




echo \" <<'RUN_AS_POWERSHELL' >/dev/null # " | Out-Null
################################################################################
# Windows POWERSHELL Codes                                                     #
################################################################################
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [console]::InputEncoding `
		= [console]::OutputEncoding `
		= New-Object System.Text.UTF8Encoding


# Scan for fundamental pathing
${env:PROJECT_PATH_PWD} = Get-Location
${env:PROJECT_PATH_AUTOMATA} = "automataCI"

if (Test-Path ".\ci.ps1") {
	# currently inside the automataCI directory.
	${env:PROJECT_PATH_ROOT} = Split-Path -Parent "${env:PROJECT_PATH_PWD}"
} elseif (Test-Path ".\${env:PROJECT_PATH_AUTOMATA}\ci.ps1") {
	# current directory is the root directory.
	${env:PROJECT_PATH_ROOT} = "${env:PROJECT_PATH_PWD}"
} else {
	# scan from current directory - bottom to top
	$__pathing = "${env:PROJECT_PATH_PWD}"
	${env:PROJECT_PATH_ROOT} = ""
	foreach ($__pathing in (${env:PROJECT_PATH_PWD}.Split("\"))) {
		if (-not [string]::IsNullOrEmpty($env:PROJECT_PATH_ROOT)) {
			${env:PROJECT_PATH_ROOT} += "\"
		}
		${env:PROJECT_PATH_ROOT} += "${__pathing}"

		if (Test-Path -Path `
			"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\ci.ps1") {
			break
		}
	}
	$null = Remove-Variable -Name __pathing

	if (-not (Test-Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\ci.ps1")) {
		Write-Error "[ ERROR ] Missing root directory.`n`n"
		exit 1
	}
}


# execute
$__process = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\ci.ps1" $args
################################################################################
# Windows POWERSHELL Codes                                                     #
################################################################################
exit $__process
<#
RUN_AS_POWERSHELL




################################################################################
# Unix Main Codes                                                              #
################################################################################
# Scan for fundamental pathing
export PROJECT_PATH_PWD="$PWD"
export PROJECT_PATH_AUTOMATA="automataCI"

if [ -f "./ci.sh" ]; then
        PROJECT_PATH_ROOT="${PWD%/*}/"
elif [ -f "./${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
        # current directory is the root directory.
        PROJECT_PATH_ROOT="$PWD"
else
        __pathing="$PROJECT_PATH_PWD"
        __previous=""
        while [ "$__pathing" != "" ]; do
                PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT}${__pathing%%/*}/"
                __pathing="${__pathing#*/}"
                if [ -f "${PROJECT_PATH_ROOT}${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
                        break
                fi

                # stop the scan if the previous pathing is the same as current
                if [ "$__previous" = "$__pathing" ]; then
                        1>&2 printf "[ ERROR ] [ ERROR ] Missing root directory.\n"
                        return 1
                fi
                __previous="$__pathing"
        done
        unset __pathing __previous
        export PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT%/*}"

        if [ ! -f "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
                1>&2 printf "[ ERROR ] [ ERROR ] Missing root directory.\n"
                exit 1
        fi
fi

# execute
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/ci.sh" "$@"
################################################################################
# Unix Main Codes                                                              #
################################################################################
exit $?
#>

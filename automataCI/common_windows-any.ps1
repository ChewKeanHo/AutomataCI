# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#               http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




# validate input
$null = I18N-Validate-Job
if ($(STRINGS-Is-Empty "${env:PROJECT_CI_JOB}") -eq 0) {
	$null = I18N-Validate-Failed
	return 1
}




# execute
function RUN-Subroutine-Exec {
	param(
		[string]$__directory,
		[string]$__name
	)


	# validate input
	if (($(STRINGS-Is-Empty "${__directory}") -eq 0) -or
		($(STRINGS-To-Uppercase "${__directory}") -eq "NONE")) {
		return 0
	}

	if ($(STRINGS-To-Uppercase "${__name}") -ne "BASELINE") {
		switch ($__job) {
		{ $_ -in "deploy" } {
			return 0 # skipped
		} default {
			# accepted
		}}
	}


	# execute
	$ci_job = STRINGS-To-Lowercase "${env:PROJECT_CI_JOB}_windows-any.ps1"
	$ci_job = "${env:PROJECT_PATH_ROOT}\${__directory}\${env:PROJECT_PATH_CI}\${ci_job}"
	if ($(FS-Is-File "$ci_job") -eq 0) {
		$null = I18N-Run "${__name}"
		$___process = . $ci_job
		if ($___process -ne 0) {
			$null = I18N-Run-Failed
			return 1
		}
	}


	# report status
	return 0
}


$___process = RUN-Subroutine-Exec "${env:PROJECT_ANGULAR}" "ANGULAR"
if ($___process -ne 0) {
	return 1
}

$___process = RUN-Subroutine-Exec "${env:PROJECT_BOOK}" "BOOK"
if ($___process -ne 0) {
	return 1
}

$___process = RUN-Subroutine-Exec "${env:PROJECT_GO}" "GO"
if ($___process -ne 0) {
	return 1
}

$___process = RUN-Subroutine-Exec "${env:PROJECT_NIM}" "NIM"
if ($___process -ne 0) {
	return 1
}

$___process = RUN-Subroutine-Exec "${env:PROJECT_NODE}" "NODE"
if ($___process -ne 0) {
	return 1
}

$___process = RUN-Subroutine-Exec "${env:PROJECT_PYTHON}" "PYTHON"
if ($___process -ne 0) {
	return 1
}

$___process = RUN-Subroutine-Exec "${env:PROJECT_RUST}" "RUST"
if ($___process -ne 0) {
	return 1
}

$___process = RUN-Subroutine-Exec "${env:PROJECT_RESEARCH}" "RESEARCH"
if ($___process -ne 0) {
	return 1
}

$___process = RUN-Subroutine-Exec "${env:PROJECT_GOOGLEAI}" "GOOGLE AI"
if ($___process -ne 0) {
	return 1
}

$___process = RUN-Subroutine-Exec "${env:PROJECT_PATH_SOURCE}" "BASELINE"
if ($___process -ne 0) {
	return 1
}

# IMPORTANT: C on unix has some issue with setting the terminal into ultra
#            strict mode after build causing other technological integrations
#            to fail after run (e.g. flatpak). Therefore, it will be placed as
#            the last one to execute.
$___process = RUN-Subroutine-Exec "${env:PROJECT_C}" "C"
if ($___process -ne 0) {
	return 1
}




# report status
I18N-Run-Successful
return 0

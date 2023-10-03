# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\deb.ps1"




function PACKAGE-Assemble-DEB-Content {
	param(
		[string]$__target,
		[string]$__directory,
		[string]$__target_name,
		[string]$__target_os,
		[string]$__target_arch
	)

	# validate target before job
	if ($(FS-Is-Target-A-Source "${__target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${__target}") -eq 0) {
		# copy main libary
		# TIP: (1) usually is: usr/local/lib
		#      (2) please avoid: lib/, lib{TYPE}/ usr/lib/, and usr/lib{TYPE}/
		$__filepath = "${__directory}\data\usr\local\lib\${env:PROJECT_SKU}"
		$__filepath = "${__filepath}\lib${env:PROJECT_SKU}.a"
		OS-Print-Status info "copying ${__target} to ${__filepath}"
		$__process = FS-Make-Housing-Directory "${__filepath}"
		if ($__process -ne 0) {
			return 1
		}

		$__process = FS-Copy-File "${__target}" "${__filepath}"
		if ($__process -ne 0) {
			return 1
		}

		$__keyring = "lib${env:PROJECT_SKU}"
	} elseif ($(FS-Is-Target-A-WASM-JS "${__target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM "${__target}") -eq 0) {
		return 10 # not applicable
	} else {
		switch (${__target_os}) {
		"windows" {
			$__dest = "${__directory}\${env:PROJECT_SKU}.exe"
		} Default {
			$__dest = "${__directory}\${env:PROJECT_SKU}"
		}}

		# copy main program
		# TIP: (1) usually is: usr/local/bin or usr/local/sbin
		#      (2) please avoid: bin/, usr/bin/, sbin/, and usr/sbin/
		$__filepath = "${__directory}\data\user\local\bin\${env:PROJECT_SKU}"
		OS-Print-Status info "copying ${__target} to ${__filepath}"
		$__process = FS-Make-Housing-Directory "${__filepath}"
		if ($__process -ne 0) {
			return 1
		}

		$__process = FS-Copy-File "${__target}" "${__filepath}"
		if ($__process -ne 0) {
			return 1
		}
	}

	OS-Print-Status info "overriding source.list file..."
	if ([string]::IsNullOrEmpty($__keyring) {
		$__keyring = "${env:PROJECT_SKU}"
	}

	$__url = "${env:PROJECT_STATIC_URL}/deb"
	$__url = $__url -replace "//deb" "/deb"
	$__process = DEB-Create-Source-List `
		"${env:PROJECT_DEBIAN_CREATE_SOURCE_LIST}" `
		"${env:PROJECT_SIMULATE_RELEASE_REPO}" `
		"${__directory}" `
		"${env:PROJECT_GPG_ID}" `
		"${__url}" `
		"${env:PROJECT_REPREPRO_CODENAME}" `
		"${env:PROJECT_DEBIAN_DISTRIBUTION}" `
		"${__keyring}"
	if ($__process -ne 0) {
		return 1
	}


	# OPTIONAL (overrides): copy usr/share/docs/${env:PROJECT_SKU}/changelog.gz
	# OPTIONAL (overrides): copy usr/share/docs/${env:PROJECT_SKU}/copyright.gz
	# OPTIONAL (overrides): copy usr/share/man/man1/${env:PROJECT_SKU}.1.gz
	# OPTIONAL (overrides): generate ${__directory}/control/md5sum
	# OPTIONAL (overrides): generate ${__directory}/control/control


	# report status
	return 0
}

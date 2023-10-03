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




function PACKAGE-Assemble-Archive-Content {
	param(
		[string]$__target,
		[string]$__directory,
		[string]$__target_name,
		[string]$__target_os,
		[string]$__target_arch
	)


	# package based on target's nature
	if ($(FS-Is-Target-A-Source "${__target}") -eq 0) {
		$__target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_GO}\libs"
		OS-Print-Status info "copying ${__target} to ${__directory}"
		$__process = FS-Copy-All "${__target}" "${__directory}"
		if ($__process -ne 0) {
			OS-Print-Status error "copy failed."
			return 1
		}

		$__process = FS-Is-File "${__directory}/go.mod"
		if ($__process -ne 0) {
			OS-Print-Status info "creating localized go.mod file..."
			FS-Write-File "${__directory}/go.mod" @"
module ${env:PROJECT_SKU}

replace ${env:PROJECT_SKU} => ./
"@
		}
	} elseif ($(FS-Is-Target-A-Library "${__target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM-JS "${__target}") -eq 0) {
		return 10 # handled by wasm instead
	} elseif ($(FS-Is-Target-A-WASM "${__target}") -eq 0) {
		OS-Print-Status info "copying ${__target} to ${__directory}"
		$__process = Fs-Copy-File "${__target}" "${__directory}"
		if ($__process -ne 0) {
			return 1
		}

		$__process = FS-Is-File "$($__target -replace '\.wasm.*$', '.js')"
		if ($__process -eq 0) {
			OS-Print-Status info `
				"copying $($__target -replace '\.wasm.*$', '.js') to ${__directory}"
			$__process = Fs-Copy-File `
					"$($__target -replace '\.wasm.*$', '.js')" `
					"${__directory}"
			if ($__process -ne 0) {
				return 1
			}
		}
	} else {
		switch (${__target_os}) {
		"windows" {
			$__dest = "${__directory}\${env:PROJECT_SKU}.exe"
		} Default {
			$__dest = "${__directory}\${env:PROJECT_SKU}"
		}}

		OS-Print-Status info "copying ${__target} to ${__dest}"
		$__process = FS-Copy-File "${__target}" "${__dest}"
		if ($__process -ne 0) {
			OS-Print-Status error "copy failed."
			return 1
		}
	}


	# copy user guide
	$__target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\docs\USER-GUIDES-EN.pdf"
	OS-Print-Status info "copying ${__target} to ${__directory}"
	$__process = FS-Copy-File "${__target}" "${__directory}"
	if ($__process -ne 0) {
		OS-Print-Status error "copy failed."
		return 1
	}


	# copy license file
	$__target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\licenses\LICENSE-EN.pdf"
	OS-Print-Status info "copying ${__target} to ${__directory}"
	$__process = FS-Copy-File "${__target}" "${__directory}"
	if ($__process -ne 0) {
		OS-Print-Status error "copy failed."
		return 1
	}


	# report status
	return 0
}

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
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# package based on target's nature
	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		$__target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_GO}\libs"
		OS-Print-Status info "copying ${_target} to ${_directory}"
		$__process = FS-Copy-All "${_target}" "${_directory}"
		if ($__process -ne 0) {
			OS-Print-Status error "copy failed."
			return 1
		}

		$__process = FS-Is-File "${_directory}/go.mod"
		if ($__process -ne 0) {
			OS-Print-Status info "creating localized go.mod file..."
			FS-Write-File "${_directory}/go.mod" @"
module ${env:PROJECT_SKU}

replace ${env:PROJECT_SKU} => ./
"@
		}
	} elseif ($(FS-Is-Target-A-Docs "${_target}") -eq 0) {
		$__process = FS-Is-Target-A-Docs "${_target}"
		if ($__process -ne 0) {
			return 10 # not applicable
		}

		$__process = FS-Copy-All `
			"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_DOCS}" `
			"${_directory}"
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM-JS "${_target}") -eq 0) {
		return 10 # handled by wasm instead
	} elseif ($(FS-Is-Target-A-WASM "${_target}") -eq 0) {
		OS-Print-Status info "copying ${_target} to ${_directory}"
		$__process = Fs-Copy-File "${_target}" "${_directory}"
		if ($__process -ne 0) {
			return 1
		}

		$__process = FS-Is-File "$($_target -replace '\.wasm.*$', '.js')"
		if ($__process -eq 0) {
			OS-Print-Status info `
				"copying $($_target -replace '\.wasm.*$', '.js') to ${_directory}"
			$__process = Fs-Copy-File `
					"$($_target -replace '\.wasm.*$', '.js')" `
					"${_directory}"
			if ($__process -ne 0) {
				return 1
			}
		}
	} elseif ($(FS-Is-Target-A-Chocolatey "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Homebrew "${_target}") -eq 0) {
		return 10 # not applicable
	} else {
		switch (${_target_os}) {
		"windows" {
			$_dest = "${_directory}\${env:PROJECT_SKU}.exe"
		} Default {
			$_dest = "${_directory}\${env:PROJECT_SKU}"
		}}

		OS-Print-Status info "copying ${_target} to ${_dest}"
		$__process = FS-Copy-File "${_target}" "${_dest}"
		if ($__process -ne 0) {
			OS-Print-Status error "copy failed."
			return 1
		}
	}


	# copy user guide
	$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\docs\USER-GUIDES-EN.pdf"
	OS-Print-Status info "copying ${_target} to ${_directory}"
	$__process = FS-Copy-File "${_target}" "${_directory}"
	if ($__process -ne 0) {
		OS-Print-Status error "copy failed."
		return 1
	}


	# copy license file
	$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\licenses\LICENSE-EN.pdf"
	OS-Print-Status info "copying ${_target} to ${_directory}"
	$__process = FS-Copy-File "${_target}" "${_directory}"
	if ($__process -ne 0) {
		OS-Print-Status error "copy failed."
		return 1
	}


	# report status
	return 0
}

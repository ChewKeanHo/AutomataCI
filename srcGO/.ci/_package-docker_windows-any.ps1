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
	exit 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"




function PACKAGE-Assemble-DOCKER-Content {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate project
	if ($(FS-Is-Target-A-Source "${_target}") -ne 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${_target}") -ne 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM-JS "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Homebrew "${_target}") -eq 0) {
		return 10 # not applicable
	}

	OS-Print-Status info "Running Go specific content assembling function..."


	# assemble the package
	$__process = FS-Copy-File "${_target}" "${_directory}\${env:PROJECT_SKU}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Touch-File "${_directory}\.blank"
	if ($__process -ne 0) {
		return 1
	}


	# generate the Dockerfile
	$__process = FS-Write-File "${_directory}\Dockerfile" @"
# Defining baseline image
FROM --platform=${_target_os}/${_target_arch} scratch
LABEL org.opencontainers.image.title=`"${env:PROJECT_NAME}`"
LABEL org.opencontainers.image.description=`"${env:PROJECT_PITCH}`"
LABEL org.opencontainers.image.authors=`"${env:PROJECT_CONTACT_NAME} <${env:PROJECT_CONTACT_EMAIL}>`"
LABEL org.opencontainers.image.version=`"${env:PROJECT_VERSION}`"
LABEL org.opencontainers.image.revision=`"${env:PROJECT_CADENCE}`"
LABEL org.opencontainers.image.licenses=`"${env:PROJECT_LICENSE}`"
"@

	if (-not ([string]::IsNullOrEmpty(${env:PROJECT_CONTACT_WEBSITE}))) {
		$__process = FS-Append-File "${_directory}\Dockerfile" @"
LABEL org.opencontainers.image.url=`"${env:PROJECT_CONTACT_WEBSITE}`"
"@
	}

	if (-not ([string]::IsNullOrEmpty(${env:PROJECT_SOURCE_URL}))) {
		$__process = FS-Append-File "${_directory}\Dockerfile" @"
LABEL org.opencontainers.image.source=`"${env:PROJECT_SOURCE_URL}`"
"@
	}

	$__process = FS-Append-File "${_directory}\Dockerfile" @"
# Defining environment variables
ENV ARCH ${_target_arch}
ENV OS ${_target_os}
ENV PORT 80

# Assemble the file structure
COPY .blank /tmp/.tmpfile
ADD ${env:PROJECT_SKU} /app/bin/${env:PROJECT_SKU}

# Set network port exposures
EXPOSE 80

# Set entry point
ENTRYPOINT ["/app/bin/${env:PROJECT_SKU}"]
"@
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}

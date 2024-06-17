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
	exit 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function PACKAGE-Assemble-DOCKER-Content {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate project
	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Docs "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM-JS "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Chocolatey "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Homebrew "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Cargo "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-MSI "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-PDF "${_target}") -eq 0) {
		return 10 # not applicable
	}

	switch ($_target_os) {
	'any' {
		$_target_image = "scratch"
		$__arch_list = ""
	} 'linux' {
		$_target_image = "${env:PROJECT_CONTAINER_BASE_LINUX}"
		$__arch_list = "${env:PROJECT_CONTAINER_BASE_LINUX_ARCH}"
	} 'windows' {
		$_target_image = "${env:PROJECT_CONTAINER_BASE_WINDOWS}"
		$__arch_list = "${env:PROJECT_CONTAINER_BASE_WINDOWS_ARCH}"
	} default {
		return 10 # not supported
	}}

	$__supported = 1
	if (($(STRINGS-Is-Empty "${__arch_list}") -ne 0) -and ($_target_image -ne "scratch")) {
		$__arch_list.Split("|") | ForEach {
			if ($_target_arch -eq $_) {
				$__supported = 0
				break
			}
		}
	} else {
		$__supported = 0
	}

	if ($__supported -ne 0) {
		return 10 # not supported
	}


	# assemble the package
	$___process = FS-Copy-File "${_target}" "${_directory}\${env:PROJECT_SKU}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Touch-File "${_directory}\.blank"
	if ($___process -ne 0) {
		return 1
	}


	# generate the Dockerfile
	$null = FS-Write-File "${_directory}\Dockerfile" @"
FROM --platform=${_target_os}/${_target_arch} ${_target_image}

LABEL org.opencontainers.image.title=`"${env:PROJECT_NAME}`"
LABEL org.opencontainers.image.description=`"${env:PROJECT_PITCH}`"
LABEL org.opencontainers.image.authors=`"${env:PROJECT_CONTACT_NAME} <${env:PROJECT_CONTACT_EMAIL}>`"
LABEL org.opencontainers.image.version=`"${env:PROJECT_VERSION}`"
LABEL org.opencontainers.image.revision=`"${env:PROJECT_CADENCE}`"
LABEL org.opencontainers.image.licenses=`"${env:PROJECT_LICENSE}`"

"@

	if ($(STRINGS-Is-Empty "${env:PROJECT_CONTACT_WEBSITE}") -ne 0) {
		$null = FS-Append-File "${_directory}\Dockerfile" @"
LABEL org.opencontainers.image.url=`"${env:PROJECT_CONTACT_WEBSITE}`"

"@
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_SOURCE_URL}") -ne 0) {
		$null = FS-Append-File "${_directory}\Dockerfile" @"
LABEL org.opencontainers.image.source=`"${env:PROJECT_SOURCE_URL}`"

"@
	}

	$___process = FS-Append-File "${_directory}\Dockerfile" @"

# Defining environment variables
ENV ARCH ${_target_arch}
ENV OS ${_target_os}
ENV PORT 80

# Assemble the file structure
COPY .blank /tmp/.placeholder
ADD --chmod 765 ${PROJECT_SKU} /usr/local/bin/${PROJECT_SKU}

# Set network port exposures
EXPOSE 80

# Set entry point
ENTRYPOINT ['/usr/local/bin/${PROJECT_SKU}']
CMD ['help']

"@
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}

# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\net\http.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\msi.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\apple.ps1"




function LIBREOFFICE-Get {
	# execute
	$null = OS-Sync

	$___source = "libreoffice"
	$___process = OS-Is-Command-Available "${___source}"
	if ($___process -eq 0) {
		return "${___source}"
	}

	$___source = "soffice"
	$___process = OS-Is-Command-Available "${___source}"
	if ($___process -eq 0) {
		return "${___source}"
	}

	$___source = "$(LIBREOFFICE-Get-Path)"
	$___process = FS-Is-File "${___source}"
	if ($___process -eq 0) {
		return $___source
	}


	# report status
	return ""
}




function LIBREOFFICE-Get-Path-Local {
	$___path = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}\${env:PROJECT_PATH_LIBREOFFICE_ENGINE}\bin\soffice"

	switch ("${env:PROJECT_OS}") {
	"windows" {
		$___path = "${___path}.exe"
	} default {
		# do nothing
	}}


	# report status
	return $___path
}




function LIBREOFFICE-Get-Path {
	# execute
	$___path = LIBREOFFICE-Get-Path-Local
	if ($(FS-Is-File "${___path}") -eq 0) {
		return $___path
	}

	switch ("${env:PROJECT_OS}") {
	"darwin" {
		$___path = "/Applications/LibreOffice.app/Contents/MacOS/soffice"
	} "windows" {
		$___path = "${___path}.exe"
		if ($(FS-Is-File "${___path}") -ne 0) {
			$___path = "C:\Program Files\LibreOffice\program\soffice.exe"
		}
	} default {
		$___path = "/bin/soffice"
	}}


	# report status
	return $___path
}




function LIBREOFFICE-Is-Available {
	# execute
	$___process = OS-Is-Command-Available "libreoffice"
	if ($___process -eq 0) {
		return 0
	}

	$___process = OS-Is-Command-Available "soffice"
	if ($___process -eq 0) {
		return 0
	}

	$___process = FS-Is-File "$(LIBREOFFICE-Get-Path)"
	if ($___process -eq 0) {
		return 0
	}


	# report status
	return 1
}




function LIBREOFFICE-Setup {
	# validate input
	$___process = LIBREOFFICE-Is-Available
	if ($___process -eq 0) {
		return 0
	}

	if (($(STRINGS-Is-Empty "${env:PROJECT_PATH_ROOT}") -eq 0) -or
		($(STRINGS-Is-Empty "${env:PROJECT_PATH_TEMP}") -eq 0) -or
		($(STRINGS-Is-Empty "${env:PROJECT_PATH_TOOLS}") -eq 0) -or
		($(STRINGS-Is-Empty "${env:PROJECT_LIBREOFFICE_MIRROR}") -eq 0) -or
		($(STRINGS-Is-Empty "${env:PROJECT_LIBREOFFICE_VERSION}") -eq 0)) {
		return 1
	}


	# execute
	$___dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}\${env:PROJECT_PATH_LIBREOFFICE_ENGINE}"
	$___url = "${env:PROJECT_LIBREOFFICE_MIRROR}/stable/${env:PROJECT_LIBREOFFICE_VERSION}"
	switch ("${env:PROJECT_OS}") {
	"darwin" {
		$___dest = "${___dest}\install.dmg"

		$___url = "${___url}/mac"
		switch ("${env:PROJECT_ARCH}") {
		"amd64" {
			$___url = "${___url}/x86_64"
			$___url = "${___url}/LibreOffice_${env:PROJECT_LIBREOFFICE_VERSION}_MacOS_x86-64.dmg"
		} "arm64" {
			$___url = "${___url}/aarch64"
			$___url = "${___url}/LibreOffice_${env:PROJECT_LIBREOFFICE_VERSION}_MacOS_aarch64.dmg"
		} default {
			$___url = ""
		}}

		## attempt to download from vendor directly
		if ($(STRINGS-Is-Empty "${___url}") -ne 0) {
			$null = FS-Make-Housing-Directory "${___dest}"
			$null = FS-Remove-Silently "${___dest}"
			$___process = HTTP-Download "GET" "${___url}" "${___dest}"
			if ($___process -ne 0) {
				return 1
			}

			$___process = Apple-Install-DMG "${___dest}"
			if ($___process -ne 0) {
				return 1
			}

			$null = FS-Remove-Silently "${___dest}"
		}
	} "windows" {
		$___dest = "${___dest}\install.msi"

		$___url = "${___url}/win"
		switch ("${env:PROJECT_ARCH}") {
		"amd64" {
			$___url = "${___url}/x86_64"
			$___url = "${___url}/LibreOffice_${env:PROJECT_LIBREOFFICE_VERSION}_Win_x86-64.msi"
		} "arm64" {
			$___url = "${___url}/aarch64"
			$___url = "${___url}/LibreOffice_${env:PROJECT_LIBREOFFICE_VERSION}_Win_aarch64.msi"
		} default {
			$___url = ""
		}}

		if ($(STRINGS-Is-Empty "${___url}") -ne 0) {
			$null = FS-Make-Housing-Directory "${___dest}"
			$null = FS-Remove-Silently "${___dest}"
			$___process = HTTP-Download "GET" "${___url}" "${___dest}"
			if ($___process -eq 0) {
				$___process = MSI-Install-Silent "${___dest}"
				$null = FS-Remove-Silently "${___dest}"
			}
		}

		## fallback to choco as the last resort
		if (($(STRINGS-Is-Empty "${___url}") -eq 0) -or ($___process -ne 0)) {
			$___process = OS-Is-Command-Available "choco"
			if ($___process -ne 0) {
				return 1
			}

			$___process = OS-Exec "choco" "install libreoffice-fresh -y"
			if ($___process -ne 0) {
				return 1
			}

			$null = OS-Sync
		}
	} "linux" {
		$___process = OS-Is-Command-Available "flatpak"
		if ($___process -eq 0) {
			$___process = OS-Exec "flatpak" "--user install org.libreoffice.LibreOffice"
		}

		## download appimage as last resort
		if ($___process -ne 0) {
			$___dest = LIBREOFFICE-Get-Path-Local
			$___url = "https://appimages.libreitalia.org"
			switch ("${env:PROJECT_ARCH}") {
			"amd64" {
				$___url = "${___url}/LibreOffice-fresh.full-x86_64.AppImage"
			} default {
				return 1
			}}

			if ($(STRINGS-Is-Empty "${___url}") -ne 0) {
				$null = FS-Make-Housing-Directory "${___dest}"
				$null = FS-Remove-Silently "${___dest}"
				$___process = HTTP-Download "GET" "${___url}" "${___dest}"
				if ($___process -ne 0) {
					return 1
				}

				$___process = FS-Is-File "${___dest}"
				if ($___process -ne 0) {
					return 1
				}
			}
		}
	} default {
		return 1 # unsupported
	}}


	# test the output
	$___process = LIBREOFFICE-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}

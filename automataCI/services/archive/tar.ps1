# Copyright 2023 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
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
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\compress\gz.ps1"
. "${env:LIBS_AUTOMATACI}\services\compress\xz.ps1"




function TAR-Is-Available {
	# validate input
	$___process = OS-Is-Command-Available "tar"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	return 0
}




function TAR-Create {
	param (
		[string]$___destination,
		[string]$___source,
		[string]$___owner,
		[string]$___group
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___destination}") -eq 0) -or
		($(STRINGS-Is-Empty "${___source}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___destination}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___destination}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = TAR-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# create tar archive
	$___supported = $false # windows' TAR system does not support UNIX UGID system
	if (($___supported) -and
		($(STRINGS-Is-Empty "${___owner}") -ne 0) -and
		($(STRINGS-Is-Empty "${___group}") -ne 0)) {
		$___arguments = "--numeric-owner --group=`"${___group}`" " `
				+ "--owner=`"${___owner}`" " `
				+ "-cvf `"${___destination}`" ${___source}"
		$___process = OS-Exec "tar" "${___arguments}"
		if ($___process -ne 0) {
			return 1
		}
	} else {
		$___process = OS-Exec "tar" "-cvf `"${___destination}`" ${___source}"
		if ($___process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}




function TAR-Create-GZ {
	param (
		[string]$___destination,
		[string]$___source,
		[string]$___owner,
		[string]$___group
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___destination}") -eq 0) -or
		($(STRINGS-Is-Empty "${___source}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___destination}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___destination}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = GZ-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	if ($($___destination -replace '\.tgz.*$') -ne $___destination) {
		$___dest = "$($___destination -replace '\.tgz.*$')"
	} else {
		$___dest = "$($___destination -replace '\.tar.gz.*$')"
	}


	# create tar archive
	$___process = TAR-Create "${___dest}.tar" "${___source}" "${___owner}" "${___group}"
	if ($___process -ne 0) {
		return 1
	}


	# compress archive
	$___process = GZ-Create "${___dest}.tar"
	if ($___process -ne 0) {
		return 1
	}


	# rename to target
	if ("${___destination}" -ne "${___dest}.tar.gz") {
		$___process = FS-Move "${___dest}.tar.gz" "${___destination}"
		if ($___process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}




function TAR-Create-XZ {
	param (
		[string]$___destination,
		[string]$___source,
		[string]$___owner,
		[string]$___group
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___destination}") -eq 0) -or
		($(STRINGS-Is-Empty "${___source}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___destination}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___destination}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = XZ-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	if ($($___destination -replace '\.txz.*$') -ne $___destination) {
		$___dest = "$($___destination -replace '\.txz.*$')"
	} else {
		$___dest = "$($___destination -replace '\.tar.xz.*$')"
	}


	# create tar archive
	$___process = TAR-Create "${___dest}.tar" "${___source}" "${___owner}" "${___group}"
	if ($___process -ne 0) {
		return 1
	}


	# compress archive
	$___process = XZ-Create "${___dest}.tar"
	if ($___process -ne 0) {
		return 1
	}


	# rename to target
	if ("${___destination}" -ne "${___dest}.tar.xz") {
		$___process = FS-Move "${___dest}.xz" "${___destination}"
		if ($___process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}




function TAR-Extract-GZ {
	param (
		[string]$___destination,
		[string]$___source
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___destination}") -eq 0) -or
		($(STRINGS-Is-Empty "${___source}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___destination}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___source}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = GZ-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# unpack tar.gz
	$___process = OS-Exec "tar" "-C `"${___destination}`" -xzf `"${___source}`""
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function TAR-Extract-XZ {
	param (
		[string]$___destination,
		[string]$___source
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___destination}") -eq 0) -or
		($(STRINGS-Is-Empty "${___source}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___destination}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___source}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = XZ-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# unpack tar.xz
	$___process = OS-Exec "tar" "-C `"${___destination}`" -xf `"${___source}`""
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}

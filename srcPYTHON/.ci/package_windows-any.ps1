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




# (0) initialize
IF (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
        Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
        exit 1
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

	# copy main program
	$__process = FS-Is-Target-A-Source "${__target}"
	if ($__process -eq 0) {
		# it's a source code target
		PYTHON-Clean-Artifact "${env:PROJECT_PATH_ROOT}\srcPYTHON"
		$__target = "${env:PROJECT_PATH_ROOT}\srcPYTHON\Libs"
		OS-Print-Status info "copying ${__target} to ${__directory}"
		$__process = FS-Copy-All "${__target}" "${__directory}"
		if ($__process -ne 0) {
			return 1
		}

		return 0
	} else {
		# it's a binary target
		switch (${__target_os}) {
		"windows" {
			$__dest = "${__directory}\${env:PROJECT_SKU}.exe"
		} Default {
			$__dest = "${__directory}\${env:PROJECT_SKU}"
		}}

		OS-Print-Status info "copying ${__target} to ${__dest}"
		$__process = Fs-Copy-File "${__target}" "${__dest}"
		if ($__process -ne 0) {
			return 1
		}
	}

	# copy user guide
	$__target = "${env:PROJECT_PATH_ROOT}\USER-GUIDES-EN.pdf"
	OS-Print-Status info "copying ${__target} to ${__directory}"
	FS-Copy-File "${__target}" "${__directory}"
	if ($__process -ne 0) {
		return 1
	}

	# copy license file
	$__target = "${env:PROJECT_PATH_ROOT}\LICENSE-EN.pdf"
	OS-Print-Status info "copying ${__target} to ${__directory}"
	FS-Copy-File "${__target}" "${__directory}"
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}




function PACKAGE-Assemble-DEB-Content {
	param(
		[string]$__target,
		[string]$__directory,
		[string]$__target_name,
		[string]$__target_os,
		[string]$__target_arch
	)

	# validate target before job
	$__process = FS-Is-Target-A-Source "${__target}"
	if ($__process -eq 0) {
		return 10
	}

	# copy main program
	# TIP: (1) usually is: usr/local/bin or usr/local/sbin
	#      (2) please avoid: bin/, usr/bin/, sbin/, and usr/sbin/
	$__filepath = "${__directory}\data\user\local\bin\${env:PROJECT_SKU}"
	OS-Print-Status info "copying ${__target} to ${__filepath}"
	$__process = FS-Make-Housing-Directory "${__filepath}"
	if ($__process -ne 0) {
		return 1
	}

	FS-Copy-File "${__target}" "${__filepath}"
	if ($process -ne 0) {
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




function PACKAGE-Assemble-RPM-Content {
	param(
		[string]$__target,
		[string]$__directory,
		[string]$__target_name,
		[string]$__target_os,
		[string]$__target_arch
	)

	# validate target before job
	$__process = FS-Is-Target-A-Source "${__target}"
	if ($__process -eq 0) {
		return 10
	}

	# copy main program
	# TIP: (1) copy all files into "${__directory}/BUILD" directory.
	$__filepath = "${__directory}\BUILD\${env:PROJECT_SKU}"
	OS-Print-Status info "copying ${__target} to ${__filepath}"
	$__process = FS-Make-Housing-Directory "${__filepath}"
	if ($__process -ne 0) {
		return 1
	}

	FS-Copy-File "${__target}" "${__filepath}"
	if ($process -ne 0) {
		return 1
	}

	# generate AutomataCI's required RPM spec instructions (INSTALL)
	$__process = FS-Write-File "${__directory}\SPEC_INSTALL" @"
install --directory %{buildroot}/usr/local/bin
install -m 0755 ${env:PROJECT_SKU} %{buildroot}/usr/local/bin

install --directory %{buildroot}/usr/local/share/doc/${env:PROJECT_SKU}/
install -m 644 copyright %{buildroot}/usr/local/share/doc/${env:PROJECT_SKU}/

install --directory %{buildroot}/usr/local/share/man/man1/
install -m 644 ${env:PROJECT_SKU}.1.gz %{buildroot}/usr/local/share/man/man1/
"@
	if ($process -ne 0) {
		return 1
	}

	# generate AutomataCI's required RPM spec instructions (FILES)
	$__process = FS-Write-File "${__directory}\SPEC_FILES" @"
/usr/local/bin/${env:PROJECT_SKU}
/usr/local/share/doc/${env:PROJECT_SKU}/copyright
/usr/local/share/man/man1/${env:PROJECT_SKU}.1.gz
"@
	if ($process -ne 0) {
		return 1
	}

	# OPTIONAL (overrides): ${__directory}/BUILD/copyright.gz
	# OPTIONAL (overrides): ${__directory}/BUILD/man.1.gz
	# OPTIONAL (overrides): ${__directory}/SPECS/${env:PROJECT_SKU}.spec

	# report status
	return 0
}




function PACKAGE-Assemble-FLATPAK-Content {
	param(
		[string]$__target,
		[string]$__directory,
		[string]$__target_name,
		[string]$__target_os,
		[string]$__target_arch
	)

	# validate target before job
	$__process = FS-Is-Target-A-Source "${__target}"
	if ($__process -eq 0) {
		return 10
	}

	# copy main program
	# TIP: (1) copy all files into "${__directory}/BUILD" directory.
	$__filepath = "${__directory}\${env:PROJECT_SKU}"
	OS-Print-Status info "copying ${__target} to ${__filepath}"
	FS-Copy-File "${__target}" "${__filepath}"
	if ($process -ne 0) {
		return 1
	}

	# copy icon.svg
	$__target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	$__target = "${__target}\icons\icon.svg"
	$__filepath = "${__directory}\icon.svg"
	OS-Print-Status info "copying ${__target} to ${__filepath}"
	FS-Copy-File "${__target}" "${__filepath}"
	if ($process -ne 0) {
		return 1
	}

	# copy icon-48x48.png
	$__target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	$__target = "${__target}\icons\icon-128x128.png"
	$__filepath = "${__directory}\icon-48x48.png"
	OS-Print-Status info "copying ${__target} to ${__filepath}"
	FS-Copy-File "${__target}" "${__filepath}"
	if ($process -ne 0) {
		return 1
	}

	# copy icon-128x128.png
	$__target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	$__target = "${__target}\icons\icon-128x128.png"
	$__filepath = "${__directory}\icon-48x48.png"
	OS-Print-Status info "copying ${__target} to ${__filepath}"
	FS-Copy-File "${__target}" "${__filepath}"
	if ($process -ne 0) {
		return 1
	}

	# OPTIONAL (overrides): copy manifest.yml or manifest.json
	# OPTIONAL (overrides): copy appdata.xml

	# report status
	return 0
}




function PACKAGE-Assemble-PYPI-Content {
	param (
		[string]$__target,
		[string]$__directory,
		[string]$__target_name,
		[string]$__target_os,
		[string]$__target_arch
	)

	# validate project
	$__process = FS-Is-Target-A-Source "$__target"
	if ($__process -ne 0) {
		return 10
	}

	if ([string]::IsNullOrEmpty($env:PROJECT_PYTHON)) {
		return 10
	}

	# assemble the python package
	PYTHON-Clean-Artifact "${env:PROJECT_PATH_ROOT}\srcPYTHON"
	$__process = FS-Copy-All "${env:PROJECT_PATH_ROOT}\srcPYTHON\Libs" "${__directory}"
	if ($__process -ne 0) {
		return 1
	}

	# generate the setup.py
	$__process = FS-Write-File "${__directory}/setup.py" @"
from setuptools import setup, find_packages

setup(
    name='${env:PROJECT_NAME}',
    version='${env:PROJECT_VERSION}',
    author='${env:PROJECT_CONTACT_NAME}',
    author_email='${env:PROJECT_CONTACT_EMAIL}',
    url='${env:PROJECT_CONTACT_WEBSITE}',
    description='${env:PROJECT_PITCH}',
    packages=find_packages(),
    long_description=open('${env:PROJECT_PATH_ROOT}\README.md').read(),
    long_description_content_type='text/markdown',
)
"@
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}

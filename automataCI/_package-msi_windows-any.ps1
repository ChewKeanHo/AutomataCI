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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\msi.ps1"
. "${env:LIBS_AUTOMATACI}\services\crypto\random.ps1"
. "${env:LIBS_AUTOMATACI}\services\hestiaLOCALE\Vanilla.sh.ps1"
. "${env:LIBS_AUTOMATACI}\services\hestiaI18N\Vanilla.sh.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function PACKAGE-Seal-MSI {
	param(
		[string]$__workspace,
		[string]$__output_directory
	)


	# obtain buildable target architecture
	$_target_arch = FS-Get-File "${__workspace}"
	$null = I18N-Check "MSI: '${_target_arch}'"
	switch (${_target_arch}) {
	{ $_ -in "amd64", "arm64", "i386", "arm" } {
		# accepted
	} default {
		$null = I18N-Check-Incompatible-Skipped
		return 0 # not supported
	}}


	# validate icon.ico is available
	$__icon_filepath = "${__workspace}\icon.ico"
	$null = I18N-Check "${__icon_filepath}"
	$___process = FS-Is-File "${__icon_filepath}"
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}


	# validate msi-banner.jpg is available
	$__banner_filepath = "${__workspace}\msi-banner.jpg"
	$null = I18N-Check "${__banner_filepath}"
	$___process = FS-Is-File "${__banner_filepath}"
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}


	# validate msi-dialog.jpg is available
	$__dialog_filepath = "${__workspace}\msi-banner.jpg"
	$null = I18N-Check "${__dialog_filepath}"
	$___process = FS-Is-File "${__dialog_filepath}"
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}


	# create wxs scripts by languages
	foreach ($__language in (-split $(hestiaI18N-Get-Languages-List))) {
		# validate LICENSE_[LANG}.rtf is available
		$__license_filepath = "${__workspace}\docs\LICENSE_${__language}.rtf"
		$null = I18N-Check "${__license_filepath}"
		$___process = FS-Is-File "${__license_filepath}"
		if ($___process -ne 0) {
			## look for generic one as last resort
			$__license_filepath = "${__workspace}\docs\LICENSE.rtf"
			$null = I18N-Check "${__license_filepath}"
			$___process = FS-Is-File "${__license_filepath}"
			if ($___process -ne 0) {
				$null = I18N-Check-Failed-Skipped
				continue ## no license file - skipping
			}
		}


		# formulate destination path
		$__dest = "${env:PROJECT_SKU}_${__language}_windows-${_target_arch}.wxs"
		$__dest = "${__workspace}\${__dest}"
		$null = I18N-Check-Availability "${__dest}"
		$___process = FS-Is-File "${__dest}"
		if ($___process -eq 0) {
			# user supplied - begin packaging
			$null = I18N-Package "${__dest}"
			$___process = MSI-Compile "${__dest}" "${_target_arch}" "${__language}"
			if ($___process -ne 0) {
				$null = I18N-Package-Failed
				return 1
			}

			continue
		}


		# creating wxs headers
		$null = I18N-Create "${__dest}"
		$___process = FS-Write-File "${__dest}" @"
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs"
	xmlns:ui="http://wixtoolset.org/schemas/v4/wxs/ui"
>
	<Package Name="${env:PROJECT_NAME}"
		Language='$(hestiaLOCALE-Get-LCID "${__language}")'
		Version='${env:PROJECT_VERSION}'
		Manufacturer='${env:PROJECT_CONTACT_NAME}'
		UpgradeCode='${env:PRODUCT_APP_UUID}'
		InstallerVersion='${env:PROJECT_MSI_INSTALLER_VERSION_WINDOWS}'
		Compressed='${env:PROJECT_MSI_COMPRESSED_MODE}'
		Codepage='${env:PROJECT_MSI_CODEPAGE}'
	>
		<SummaryInformation
			Keywords='Installer'
			Description="${env:PROJECT_NAME} (${env:PROJECT_VERSION})"
		/>

		<!-- Declare icon file -->
		<Icon Id='Icon.exe' SourceFile='${__icon_filepath}' />

		<!-- Configure upgrade settings -->
		<MajorUpgrade AllowSameVersionUpgrades='yes'
			DowngradeErrorMessage='$(hestiaI18N-Translate-Already-Latest-Version `
							"${__language}")'
		/>

		<!-- Configure 'Add/Remove Programs' interfaces -->
		<Property Id='ARPPRODUCTICON' Value='Icon.exe' />
		<Property Id='ARPHELPLINK' Value='${env:PROJECT_CONTACT_WEBSITE}' />

		<!-- Remove repair -->
		<Property Id='ARPNOREPAIR' Value='yes' Secure='yes' /><!-- Remove repair -->

		<!-- Remove modify -->
		<Property Id='ARPNOMODIFY' Value='yes' Secure='yes' /><!-- Remove modify -->

		<!-- Configure installer main sequences -->
		<CustomAction Id='Wix4Set${env:PROJECT_MSI_ARP_INSTALL_LOCATION}_X86'
			Property='${env:PROJECT_MSI_ARP_INSTALL_LOCATION}'
			Value='[${env:PROJECT_MSI_INSTALL_DIRECTORY}]' />
		<CustomAction Id='Wix4Set${env:PROJECT_MSI_ARP_INSTALL_LOCATION}_X64'
			Property='${env:PROJECT_MSI_ARP_INSTALL_LOCATION}'
			Value='[${env:PROJECT_MSI_INSTALL_DIRECTORY}]' />
		<CustomAction Id='Wix4Set${env:PROJECT_MSI_ARP_INSTALL_LOCATION}_A64'
			Property='${env:PROJECT_MSI_ARP_INSTALL_LOCATION}'
			Value='[${env:PROJECT_MSI_INSTALL_DIRECTORY}]' />
		<InstallExecuteSequence>
			<!-- Determine the install location after validated by the installer -->
			<Custom Action='Wix4Set${env:PROJECT_MSI_ARP_INSTALL_LOCATION}_X86'
				After='InstallValidate'
			></Custom>
			<Custom Action='Wix4Set${env:PROJECT_MSI_ARP_INSTALL_LOCATION}_X64'
				After='InstallValidate'
			></Custom>
			<Custom Action='Wix4Set${env:PROJECT_MSI_ARP_INSTALL_LOCATION}_A64'
				After='InstallValidate'
			></Custom>
		</InstallExecuteSequence>

		<!-- Configure backward compatible multi-mediums (e.g. Floppy disks, CDs) -->
		<Media Id='1' Cabinet='media1.cab' EmbedCab='yes' />

		<!-- Configure installer launch condition -->
		<Launch Condition='$(MSI-Get-Directory-Program-Files "${_target_arch}")'
			Message='$(hestiaI18N-Translate-Only-Install-On-Windows `
					"${__language}" `
					"${_target_arch}")' />

		<!-- Configure ${env:PROJECT_MSI_INSTALL_DIRECTORY} from CMD -->
		<CustomAction Id='Wix4SaveCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_X86'
			Property='CMDLINE_${env:PROJECT_MSI_INSTALL_DIRECTORY}'
			Value='[${env:PROJECT_MSI_INSTALL_DIRECTORY}]'
			Execute='firstSequence'
		/>
		<CustomAction Id='Wix4SetFromCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_X86'
			Property='${env:PROJECT_MSI_INSTALL_DIRECTORY}'
			Value='[${env:PROJECT_MSI_INSTALL_DIRECTORY}]'
			Execute='firstSequence'
		/>
		<CustomAction Id='Wix4SaveCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_X64'
			Property='CMDLINE_${env:PROJECT_MSI_INSTALL_DIRECTORY}'
			Value='[${env:PROJECT_MSI_INSTALL_DIRECTORY}]'
			Execute='firstSequence'
		/>
		<CustomAction Id='Wix4SetFromCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_X64'
			Property='${env:PROJECT_MSI_INSTALL_DIRECTORY}'
			Value='[${env:PROJECT_MSI_INSTALL_DIRECTORY}]'
			Execute='firstSequence'
		/>
		<CustomAction Id='Wix4SaveCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_A64'
			Property='CMDLINE_${env:PROJECT_MSI_INSTALL_DIRECTORY}'
			Value='[${env:PROJECT_MSI_INSTALL_DIRECTORY}]'
			Execute='firstSequence'
		/>
		<CustomAction Id='Wix4SetFromCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_A64'
			Property='${env:PROJECT_MSI_INSTALL_DIRECTORY}'
			Value='[${env:PROJECT_MSI_INSTALL_DIRECTORY}]'
			Execute='firstSequence'
		/>
		<InstallUISequence>
			<Custom Action='Wix4SaveCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_X86'
				Before='AppSearch' />
			<Custom Action='Wix4SetFromCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_X86'
				After='AppSearch'
				Condition='CMDLINE_${env:PROJECT_MSI_INSTALL_DIRECTORY}'
			/>
			<Custom Action='Wix4SaveCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_X64'
				Before='AppSearch' />
			<Custom Action='Wix4SetFromCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_X64'
				After='AppSearch'
				Condition='CMDLINE_${env:PROJECT_MSI_INSTALL_DIRECTORY}'
			/>
			<Custom Action='Wix4SaveCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_A64'
				Before='AppSearch' />
			<Custom Action='Wix4SetFromCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_A64'
				After='AppSearch'
				Condition='CMDLINE_${env:PROJECT_MSI_INSTALL_DIRECTORY}'
			/>
		</InstallUISequence>
		<InstallExecuteSequence>
			<Custom Action='Wix4SaveCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_X86'
				Before='AppSearch' />
			<Custom Action='Wix4SetFromCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_X86'
				After='AppSearch'
				Condition='CMDLINE_${env:PROJECT_MSI_INSTALL_DIRECTORY}'
			/>
			<Custom Action='Wix4SaveCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_X64'
				Before='AppSearch' />
			<Custom Action='Wix4SetFromCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_X64'
				After='AppSearch'
				Condition='CMDLINE_${env:PROJECT_MSI_INSTALL_DIRECTORY}'
			/>
			<Custom Action='Wix4SaveCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_A64'
				Before='AppSearch' />
			<Custom Action='Wix4SetFromCMD${env:PROJECT_MSI_INSTALL_DIRECTORY}_A64'
				After='AppSearch'
				Condition='CMDLINE_${env:PROJECT_MSI_INSTALL_DIRECTORY}'
			/>
		</InstallExecuteSequence>
		<Property Id='${env:PROJECT_MSI_INSTALL_DIRECTORY}'>
			<RegistrySearch Id='DetermineInstallLocation'
				Type='raw'
				Root='HKLM'
				Key='${env:PROJECT_MSI_REGISTRY_KEY}'
				Name='${env:PROJECT_MSI_REGISTRY_NAME}'
			/>
		</Property>

		<!-- Define directory structures -->
		<StandardDirectory Id='$(MSI-Get-Directory-Program-Files "${_target_arch}")'>
		<Directory Id='${env:PROJECT_SCOPE}DIR' Name='${env:PROJECT_SCOPE}'>
		<Directory Id='${env:PROJECT_MSI_INSTALL_DIRECTORY}' Name='${env:PROJECT_SKU}'>

"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}

		$__source = "${__workspace}\bin"
		$___process = FS-Is-Directory-Empty "${__source}"
		if ($___process -ne 0) {
			$___process = FS-Append-File "${__dest}" @"
			<Directory Id='FolderBin' Name='bin'></Directory>

"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}
		}

		$__source = "${__workspace}\config"
		$___process = FS-Is-Directory-Empty "${__source}"
		if ($___process -ne 0) {
			$___process = FS-Append-File "${__dest}" @"
			<Directory Id='FolderConfig' Name='config'></Directory>

"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}
		}

		$__source = "${__workspace}\lib"
		$___process = FS-Is-Directory-Empty "${__source}"
		if ($___process -ne 0) {
			$___process = FS-Append-File "${__dest}" @"
			<Directory Id='FolderLib' Name='lib'></Directory>

"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}
		}


		# Close directory tree definitions
		$___process = FS-Append-File "${__dest}" @"
		</Directory></Directory></StandardDirectory>

"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}


		## begin assemble bin/* files
		$__source = "${__workspace}\bin"
		$___process = FS-Is-Directory-Empty "${__source}"
		if ($___process -ne 0) {
			## write the opener
			$___process = FS-Append-File "${__dest}" @"
		<!-- Compulsory Executable Here -->
		<ComponentGroup Id='ProductExecutables' Directory='FolderBin'>
		<Component Id='${env:PROJECT_MSI_BIN_COMPONENT_ID}'
			Guid='${env:PROJECT_MSI_BIN_COMPONENT_GUID}'>
"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}

			## loop through each file and create the following
			foreach ($__file in (Get-ChildItem "${__source}" -File)) {
			$___process = FS-Append-File "${__dest}" @"
			<File Id='Bin_$(RANDOM-Create-STRING "33")' Source='${__file}' />

"@
			}

			## write the closure
			$___process = FS-Append-File "${__dest}" @"
		</Component>
		</ComponentGroup>
"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}
		}


		## begin assemble config/* files
		$__source = "${__workspace}\config"
		$___process = FS-Is-Directory-Empty "${__source}"
		if ($___process -ne 0) {
			## write the opener
			$___process = FS-Append-File "${__dest}" @"
		<!-- Compulsory Executable Here -->
		<ComponentGroup Id='ProductConfigs' Directory='FolderConfig'>
		<Component Id='${env:PROJECT_MSI_CONFIG_COMPONENT_ID}'
			Guid='${env:PROJECT_MSI_CONFIG_COMPONENT_GUID}'>
"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}

			## loop through each file and create the following
			foreach ($__file in (Get-ChildItem "${__source}" -File)) {
			$___process = FS-Append-File "${__dest}" @"
			<File Id='Config_$(RANDOM-Create-STRING "33")' Source='${__file}' />

"@
			}

			## write the closure
			$___process = FS-Append-File "${__dest}" @"
		</Component>
		</ComponentGroup>
"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}
		}


		## begin assemble lib/* files
		$__source = "${__workspace}\lib"
		$___process = FS-Is-Directory-Empty "${__source}"
		if ($___process -ne 0) {
			## write the opener
			$___process = FS-Append-File "${__dest}" @"
		<!-- Compulsory Executable Here -->
		<ComponentGroup Id='ProductLibraries' Directory='FolderLib'>
		<Component Id='${env:PROJECT_MSI_LIB_COMPONENT_ID}'
			Guid='${env:PROJECT_MSI_LIB_COMPONENT_GUID}'>
"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}

			## loop through each file and create the following
			foreach ($__file in (Get-ChildItem "${__source}" -File)) {
			$___process = FS-Append-File "${__dest}" @"
			<File Id='Lib_$(RANDOM-Create-STRING "33")' Source='${__file}' />

"@
			}

			## write the closure
			$___process = FS-Append-File "${__dest}" @"
		</Component>
		</ComponentGroup>
"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}
		}


		## begin assemble docs/* files
		$__source = "${__workspace}\docs"
		$___process = FS-Is-Directory-Empty "${__source}"
		if ($___process -ne 0) {
			## write the opener
			$___process = FS-Append-File "${__dest}" @"
		<!-- Compulsory Executable Here -->
		<ComponentGroup Id='ProductDocs'
			Directory='${env:PROJECT_MSI_INSTALL_DIRECTORY}'>
		<Component Id='${env:PROJECT_MSI_DOCS_COMPONENT_ID}'
			Guid='${env:PROJECT_MSI_DOCS_COMPONENT_GUID}'>
"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}

			## loop through each file and create the following
			foreach ($__file in (Get-ChildItem "${__source}" -File)) {
			$___process = FS-Append-File "${__dest}" @"
			<File Id='Docs_$(RANDOM-Create-STRING "33")' Source='${__file}' />

"@
			}

			## write the closure
			$___process = FS-Append-File "${__dest}" @"
		</Component>
		</ComponentGroup>
"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}
		}


		# create registry key
		$___process = FS-Append-File "${__dest}" @"
		<Component Id='${env:PROJECT_MSI_REGISTRIES_ID}'
			Guid='${env:PROJECT_MSI_REGISTRIES_GUID}'>
			<RegistryKey Root='HKLM' Key='${env:PROJECT_MSI_REGISTRY_KEY}'>
			<!-- IMPORTANT NOTE: DO NOT REMOVE this default entry -->
			<RegistryValue
				Name='${env:PROJECT_MSI_REGISTRY_NAME}'
				Value='[${env:PROJECT_MSI_INSTALL_DIRECTORY}]'
				Type='string'
				KeyPath='yes'
			/>

			<!-- IMPORTANT NOTE:                                 -->
			<!--     DO NOT use default registries here.         -->
			<!--     They are removable by uninstall/upgrade.    -->
			<!--     Use %APPDATA% and etc instead.              -->
		</RegistryKey></Component>

"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}


		# Define all feature components
		$___process = FS-Append-File "${__dest}" @"
		<Feature Id='${env:PROJECT_MSI_FEATURES_ID}'
			Title='$(hestiaI18N-Translate-All-Components-Title "${__language}")'
			Description='$(hestiaI18N-Translate-All-Components-Description `
						"${__language}")'
			Level='1'
			Display='expand'
			ConfigurableDirectory='${env:PROJECT_MSI_INSTALL_DIRECTORY}'
		>
			<Feature Id='${env:PROJECT_MSI_MAIN_FEATURE_ID}'
				Title='$(hestiaI18N-Translate-Main-Components-Title `
						"${__language}")'
				Description='$(hestiaI18N-Translate-Main-Components-Description `
						"${__language}")'
				Level='1'
			>
				<ComponentRef Id='${env:PROJECT_MSI_REGISTRIES_ID}' />
			</Feature>
"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}


		# write bin feature list
		$___process = FS-Is-Directory-Empty "${__workspace}\bin"
		if ($___process -ne 0) {
			$___process = FS-Append-File "${__dest}" @"
			<Feature Id='${env:PROJECT_MSI_BIN_FEATURE_ID}'
				Title='$(hestiaI18N-Translate-Bin-Components-Title `
						"${__language}")'
				Description='$(hestiaI18N-Translate-Bin-Components-Description `
						"${__language}")'
				Level='1'
			>
				<ComponentRef Id='${env:PROJECT_MSI_BIN_COMPONENT_ID}' />
			</Feature>

"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}
		}


		# write config feature list
		$___process = FS-Is-Directory-Empty "${__workspace}\config"
		if ($___process -ne 0) {
			$___process = FS-Append-File "${__dest}" @"
			<Feature Id='${env:PROJECT_MSI_CONFIG_FEATURE_ID}'
				Title='$(hestiaI18N-Translate-Config-Components-Title `
						"${__language}")'
				Description='$(hestiaI18N-Translate-Config-Components-Description `
						"${__language}")'
				Level='1'
			>
				<ComponentRef Id='${env:PROJECT_MSI_CONFIG_COMPONENT_ID}' />
			</Feature>

"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}
		}


		# write lib feature list
		$___process = FS-Is-Directory-Empty "${__workspace}\lib"
		if ($___process -ne 0) {
			$___process = FS-Append-File "${__dest}" @"
			<Feature Id='${env:PROJECT_MSI_LIB_FEATURE_ID}'
				Title='$(hestiaI18N-Translate-Lib-Components-Title `
						"${__language}")'
				Description='$(hestiaI18N-Translate-Lib-Components-Description `
						"${__language}")'
				Level='1'
			>
				<ComponentRef Id='${env:PROJECT_MSI_LIB_COMPONENT_ID}' />
			</Feature>

"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}
		}


		# write docs feature list
		$___process = FS-Is-Directory-Empty "${__workspace}\docs"
		if ($___process -ne 0) {
			$___process = FS-Append-File "${__dest}" @"
			<Feature Id='${env:PROJECT_MSI_DOCS_FEATURE_ID}'
				Title='$(hestiaI18N-Translate-Docs-Components-Title `
						"${__language}")'
				Description='$(hestiaI18N-Translate-Docs-Components-Description `
						"${__language}")'
				Level='1'
			>
				<ComponentRef Id='${env:PROJECT_MSI_DOCS_COMPONENT_ID}' />
			</Feature>

"@
			if ($___process -ne 0) {
				$null = I18N-Create-Failed
				return 1
			}
		}


		# close feature list
		$___process = FS-Append-File "${__dest}" @"
		</Feature>

"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}


		# Add standard UI support
		$___process = FS-Append-File "${__dest}" @"
		<!-- UI Customization -->
		<ui:WixUI Id='WixUI_FeatureTree' InstallDirectory='${env:PROJECT_MSI_INSTALL_DIRECTORY}' />
		<WixVariable Id='WixUIBannerBmp' Value='${__banner_filepath}' />
		<WixVariable Id='WixUIDialogBmp' Value='${__dialog_filepath}' />
		<WixVariable Id="WixUILicenseRtf" Value='${__license_filepath}' />

"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}


		# conclude the wxs write-up
		$___process = FS-Append-File "${__dest}" @"
	</Package>
</Wix>

"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}


		# begin packaging
		$null = I18N-Package "${__dest}"
		$___process = MSI-Compile "${__dest}" "${_target_arch}" "${__language}"
		if ($___process -ne 0) {
			$null = I18N-Package-Failed
			return 1
		}
	}


	# begin export packages
	foreach ($__line in (Get-ChildItem -Path "${__workspace}" -File `
	| Where-Object { ($_.Name -like "*.msi") })) {
		$__dest = "${__output_directory}\$(FS-Get-File "${__line}")"

		$null = I18N-Export "${__dest}"
		$___process = FS-Copy-File "${__line}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Export-Failed
			return 1
		}
	}


	# report status
	return 0
}




function PACKAGE-Sort-MSI {
	param(
		[string]$__workspace
	)


	# execute
	$__source = "${__workspace}\any"
	$null = I18N-Check "${__source}"
	$___process = FS-Is-Directory "${__source}"
	if ($___process -ne 0) {
		return 0 # nothing to sort - report status
	}

	:arch_loop foreach ($_arch in (Get-ChildItem -Path "${__workspace}" -Directory)) {
		$_arch = $_arch.FullName
		$___process = FS-Is-Directory "${_arch}"
		if ($___process -ne 0) {
			continue arch_loop
		}

		if ("$(FS-Get-File "${_arch}")" -eq "any") {
			continue arch_loop
		}

		# begin merging from any
		:any_loop foreach ($__target in (Get-ChildItem -Path "${__workspace}\any")) {
			$__target = $__target.FullName

			$___process = FS-Is-File "${__target}"
			if ($___process -eq 0) {
				$__dest = FS-Get-File "${__target}"
				$__dest = "${_arch}\${__dest}"
				$null = I18N-Copy "${__target}" "${__dest}"
				$___process = FS-Is-File "${__dest}"
				if ($___process -eq 0) {
					$null = I18N-Copy-Exists-Skipped
					continue any_loop  # do not overwrite
				}

				$___process = FS-Copy-File "${__target}" "${__dest}"
				if ($___process -ne 0) {
					$null = I18N-Copy-Failed
					return 1
				}

				continue any_loop
			}


			# it's a directory, loop it
			:any_dir_loop foreach ($__file in (Get-ChildItem -Path "${__target}")) {
				$__file = $__file.FullName

				$___process = FS-Is-File "${__file}"
				if ($___process -ne 0) {
					continue any_dir_loop
				}

				$__dest = "$(FS-Get-File "${__file}")"
				$__dest = "${_arch}\$(FS-Get-File "${__target}")\${__dest}"
				$null = I18N-Copy "${__file}" "${__dest}"
				$___process = FS-Is-File "${__dest}"
				if ($___process -eq 0) {
					$null = I18N-Copy-Exists-Skipped
					continue any_dir_loop # do not overwrite
				}

				$___process = FS-Copy-File "${__file}" "${__dest}"
				if ($___process -ne 0) {
					$null = I18N-Copy-Failed
					return 1
				}
			}
		}
	}


	# remove 'any' to prevent bad compilation
	$___process = FS-Remove "${__workspace}/any"
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}


	# report status
	return 0
}




function PACKAGE-Run-MSI {
	param (
		[string]$__line
	)


	# parse input
	$__list = $__line -split "\|"
	$_dest = $__list[0]
	$_target = $__list[1]
	$_target_filename = $__list[2]
	$_target_os = $__list[3]
	$_target_arch = $__list[4]
	$_src = $__list[5]


	# validate input
	$null = I18N-Check-Availability "MSI"
	$___process = MSI-Is-Available
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 0
	}


	# prepare workspace and required values
	$null = I18N-Create-Package "MSI"
	$_src = "${_src}\${_target_arch}"
	$null = FS-Make-Directory "${_src}\bin"
	$null = FS-Make-Directory "${_src}\config"
	$null = FS-Make-Directory "${_src}\docs"
	$null = FS-Make-Directory "${_src}\ext"
	$null = FS-Make-Directory "${_src}\lib"


	# copy all complimentary files to the workspace
	$null = I18N-Check-Function "PACKAGE-Assemble-MSI-Content"
	$___process = OS-Is-Command-Available "PACKAGE-Assemble-MSI-Content"
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}

	$null = I18N-Assemble-Package
	$___process = PACKAGE-Assemble-MSI-Content `
		"${_target}" `
		"${_src}" `
		"${_target_filename}" `
		"${_target_os}" `
		"${_target_arch}"
	switch ($___process) {
	10 {
		$null = I18N-Assemble-Skipped
		$null = FS-Remove-Silently "${_src}"
		return 0
	} 0 {
		# accepted
	} Default {
		$null = I18N-Assemble-Failed
		return 1
	}}


	# report status
	return 0
}

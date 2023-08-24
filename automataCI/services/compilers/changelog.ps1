# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
function CHANGELOG-Is-Available {
	$program = Get-Command git -ErrorAction SilentlyContinue
	if (-not ($program)) {
		return 1
	}

	return 0
}

function CHANGELOG-Build-Data-Entry {
	param(
		[string]$Directory,
		[string]$Version
	)

	# set to latest if not available
	if ([string]::IsNullOrEmpty($Version)) {
		$Version = "latest"
	}

	# get last tag from git log
	$LastTag = Invoke-Expression "git rev-list --tags --max-count=1"
	if ([string]::IsNullOrEmpty($LastTag)) {
		$LastTag = Invoke-Expression "git rev-list --max-parents=0 --abbrev-commit HEAD"
	}

	# generate log file from the latest to the last tag
	$Directory = "$Directory\data"
	$null = New-Item -ItemType Directory -Path "$Directory" -Force
	Invoke-Expression "git log --pretty=oneline HEAD...$LastTag" `
		| Out-File -FilePath "$Directory\.$Version" -Encoding utf8
	get-content "$Directory\.$Version"
	if (-not (Test-Path "$Directory\.$Version")) {
		Remove-Variable -Name "Directory"
		Remove-Variable -Name "Version"
		Remove-Variable -Name "LastTag"
		return 1
	}

	# good file, update the previous
	$null = Remove-Item "$Directory\$Version" `
		-Recurse `
		-Force `
		-ErrorAction SilentlyContinue
	$null = Move-Item -Path "$Directory\.$Version" `
			-Destination "$Directory\$Version" `
			-Force
	$ExitCode = $?

	# report verdict
	$null = Remove-Variable -Name "Directory"
	$null = Remove-Variable -Name "Version"
	$null = Remove-Variable -Name "LastTag"
	if ($ExitCode) {
		return 0
	}
	return 1
}

function CHANGELOG-Build-DEB-Entry {
	param (
		[string]$Directory,
		[string]$Version,
		[string]$SKU,
		[string]$Dist,
		[string]$Urgency,
		[string]$Name,
		[string]$Email,
		[string]$Date
	)

	if ([string]::IsNullOrEmpty($Version)) {
		$Version = "latest"
	}

	if ((-not (Test-Path -Path "$Directory\data\$Version")) -or
		[string]::IsNullOrEmpty($SKU) -or
		[string]::IsNullOrEmpty($Dist) -or
		[string]::IsNullOrEmpty($Urgency) -or
		[string]::IsNullOrEmpty($Name) -or
		[string]::IsNullOrEmpty($Email) -or
		[string]::IsNullOrEmpty($Date)) {
		$null = Remove-Variable -Name "Directory"
		$null = Remove-Variable -Name "Version"
		$null = Remove-Variable -Name "SKU"
		$null = Remove-Variable -Name "Dist"
		$null = Remove-Variable -Name "Urgency"
		$null = Remove-Variable -Name "Name"
		$null = Remove-Variable -Name "Email"
		$null = Remove-Variable -Name "Date"
		return 1
	}

	# all good. Generate the log fragment
	$null = New-Item -ItemType Directory -Path "$Directory\deb" -Force

	# create the entry header
	"$SKU ($Version) $Dist; urgency=$Urgency" `
		| Out-File -FilePath "$Directory\deb\.$Version" -Encoding utf8

	# generate body line-by-line
	"" | Out-File -FilePath "$Directory\deb\.$Version" -Encoding utf8 -Append
	Get-Content -Path "$Directory\data\$Version" | ForEach-Object {
		$line = $_.Substring(0, [Math]::Min($_.Length, 80))
		"  * $line" `
			| Out-File -FilePath "$Directory\deb\.$Version" -Encoding utf8 -Append
	}
	"" | Out-File -FilePath "$Directory\deb\.$Version" -Encoding utf8 -Append

	# create the entry sign-off
	"-- $Name <$Email>  $Date" `
		| Out-File -FilePath "$Directory\deb\.$Version" -Encoding utf8 -Append

	# good file, update the previous
	$null = Move-Item -Path "$Directory\deb\.$Version" `
		-Destination "$Directory\deb\$Version" `
		-Force
	$exit = $?

	# report status
	$null = Remove-Variable -Name "Directory"
	$null = Remove-Variable -Name "Version"
	$null = Remove-Variable -Name "SKU"
	$null = Remove-Variable -Name "Dist"
	$null = Remove-Variable -Name "Urgency"
	$null = Remove-Variable -Name "Name"
	$null = Remove-Variable -Name "Email"
	$null = Remove-Variable -Name "Date"
	if (!$exit) {
		return 1
	}
	return 0
}

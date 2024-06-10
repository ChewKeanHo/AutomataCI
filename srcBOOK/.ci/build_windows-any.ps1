# Copyright 2024 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
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




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\libreoffice.ps1"




# execute
$null = I18N-Activate-Environment
$___process = LIBREOFFICE-Is-Available
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}




# setup important variables
function Build-Book {
	param(
		[string]$___input,
		[string]$___name
	)


	# build PDF
	$___source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_BOOK}\${___input}"
	$___dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\build-${___name}"
	$null = I18N-Prepare "${___source}"
	$___process = FS-Is-File "${___source}"
	if ($___process -ne 0) {
		$null = I18N-Prepare-Failed
		return 1
	}
	$null = FS-Remake-Directory "${___dest}"


	## IMPORTANT: refer the following page for modifying parameters:
	##   https://help.libreoffice.org/latest/en-US/text/shared/guide/pdf_params.html
	$null = I18N-Build "${___source}"
	$___process = OS-Exec "$(LIBREOFFICE-Get)" @"
--headless --convert-to "pdf:writer_pdf_Export:{
	"UseLosslessCompression": true,
	"Quality": 100,
	"SelectPdfVersion": 0,
	"PDFUACompliance": false,
	"UseTaggedPDF": true,
	"ExportFormFields": true,
	"FormsType": 1,
	"ExportBookmarks": true,
	"ExportPlaceholders": true,
}" --outdir "${___dest}" "${___source}"
"@
	if ($___process -ne 0) {
		$null = I18N-Build-Failed
		return 1
	}


	## export output
	$___source = "${___dest}\$(FS-Get-File "${___source}")"
	$___source = FS-Extension-Replace "${___source}" ".odt" ".pdf"
	$___dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${___name}.pdf"

	$___process = FS-Is-File "${___source}"
	if ($___process -ne 0) {
		$null = I18N-Build-Failed
		return 1
	}

	$null = I18N-Export "${___dest}"
	$null = FS-Remove-Silently "${___dest}"
	$null = FS-Make-Housing-Directory "${___dest}"
	$___process = FS-Copy-File "${___source}" "${___dest}"
	if ($___process -ne 0) {
		$null = I18N-Export-Failed
		return 1
	}


	# report status
	return 0
}




# build books
$___process = Build-Book "en.odt" "${env:PROJECT_SKU}_${env:PROJECT_VERSION}_en_any-any"
if ($___process -ne 0) {
	return 1
}




# report status
return 0

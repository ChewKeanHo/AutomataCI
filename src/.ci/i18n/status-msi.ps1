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
. "${env:LIBS_AUTOMATACI}\services\i18n\printer.ps1"




function I18N-Status-Print-MSI-WXS-Script-Close {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print info "writing compulsory closures...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-MSI-WXS-Script-Compulsory-Headers {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print info "writing compulsory headers...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-MSI-WXS-Script-Features {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print info "writing features list...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-MSI-WXS-Script-Filesystem {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print info "writing filesystem structures...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-MSI-WXS-Script-Registries {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print info "writing registries component...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-MSI-WXS-Script-Start {
	param(
		[string]$___subject
	)


	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$___subject = I18N-Status-Param-Process "${___subject}"
		$null = I18N-Status-Print info "begin scripting for: ${___subject}`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-MSI-WXS-Script-UI {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print info "writing UI components...`n"
	}}


	# report status
	return 0
}

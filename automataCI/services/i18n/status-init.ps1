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




function I18N-Status-Print-Missing-CONFIG-TOML {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print error "missing 'CONFIG.toml' file.`n`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Unknown-ACTION {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print error "unsupported ACTION.`n`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Unsupported-ARCH {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print error "unsupported ARCH.`n`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Unsupported-OS {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print error "unsupported OS.`n`n"
	}}


	# report status
	return 0
}

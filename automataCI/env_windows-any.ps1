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
        Write-Error "[ ERROR ] - Please source from ci.cmd instead!\n"
        exit 1
}




# (1) construct json array
$__output = ""



if (-not ([string]::IsNullOrEmpty($env:PROJECT_PYTHON))) {
	if (-not ([string]::IsNullOrEmpty($__output))) {
		$__output = "${__output} "
	}

	$__output = $__output + "python"
}




# (2) print output
$__output = "value='${__output}'"

if (Test-Path "${env:GITHUB_OUTPUT}") {
	echo $__output >> ${env:GITHUB_OUTPUT}
}

Write-Host $__output

return 0

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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"




function GIT-At-Root-Repo {
	param(
		[string]$__directory
	)


	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		(-not (Test-Path -PathType Directory -Path "${__directory}"))) {
		return 1
	}


	# execute
	if (Test-Path -Path "${__directory}\.git\config") {
		return 0
	}


	# report status
	return 1
}




function GIT-Autonomous-Commit {
	param(
		[string]$__tracker,
		[string]$__repo,
		[string]$__branch
	)


	# validate input
	if ([string]::IsNullOrEmpty($__tracker) -or
		[string]::IsNullOrEmpty($__repo) -or
		[string]::IsNullOrEmpty($__branch)) {
		return 1
	}

	$__process = GIT-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__process = Invoke-Expression "git status --porcelain"
	if ([string]::IsNullOrEmpty($__process)) {
		return 0 # nothing to commit
	}


	# execute
	$__process = OS-Exec "git" "add ."
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Exec "git" "commit -m 'Publish as of ${__tracker}'"
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Exec "git" "push ${__repo} ${__branch}"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Autonomous-Force-Commit {
	param(
		[string]$__tracker,
		[string]$__repo,
		[string]$__branch
	)


	# validate input
	if ([string]::IsNullOrEmpty($__tracker) -or
		[string]::IsNullOrEmpty($__repo) -or
		[string]::IsNullOrEmpty($__branch)) {
		return 1
	}

	$__process = GIT-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__process = Invoke-Expression "git status --porcelain"
	if ([string]::IsNullOrEmpty($__process)) {
		return 0 # nothing to commit
	}


	# execute
	$__process = OS-Exec "git" "add ."
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Exec "git" "commit -m 'Publish as of ${__tracker}'"
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Exec "git" "push -f ${__repo} ${__branch}"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Clone {
	param (
		[string]$__url,
		[string]$__name
	)


	# validate input
	if ([string]::IsNullOrEmpty($__url)) {
		return 1
	}

	$__process = GIT-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	if (-not ([string]::IsNullOrEmpty($__url))) {
		if (Test-Path $__name) {
			return 1
		}

		if (Test-Path $__name -PathType Container) {
			return 2
		}
	}


	# execute
	if (-not ([string]::IsNullOrEmpty($__url))) {
		$__process = Os-Exec "git" "clone ${__url} ${__name}"
	} else {
		$__process = Os-Exec "git" "clone ${__url}"
	}


	# report status
	if ($__process -eq 0) {
		return 0
	}

	return 1
}




function GIT-Get-First-Commit-ID {
	# validate input
	$__process = GIT-Is-Available
	if ($__process -ne 0) {
		return ""
	}


	# execute
	$__value = Invoke-Expression "git rev-list --max-parents=0 --abbrev-commit HEAD"
	if (-not [string]::IsNullOrEmpty($__value)) {
		return $__value
	}

	return ""
}




function GIT-Get-Latest-Commit-ID {
	# validate input
	$__process = GIT-Is-Available
	if ($__process -ne 0) {
		return ""
	}


	# execute
	$__value = Invoke-Expression "git rev-parse HEAD"
	if (-not [string]::IsNullOrEmpty($__value)) {
		return $__value
	}
	return ""
}




function GIT-Get-Root-Directory {
	# validate input
	$__process = GIT-Is-Available
	if ($__process -ne 0) {
		return ""
	}
i

	# execute
	$__value = Invoke-Expression "git rev-parse --show-toplevel"
	if (-not [string]::IsNullOrEmpty($__value)) {
		return $__value
	}


	# report status
	return ""
}




function GIT-Hard-Reset-To-Init {
	param (
		[string]$__root
	)


	# validate input
	if ([string]::IsNullOrEmpty($__root)) {
		return 1
	}

	$__process = GIT-Is-Available
	if ($__process -ne 0) {
		return 1
	}


	# CVE-2023-42798 - Make sure the directory is not the same as the root
	#                  directory. If it does, bail out immediately and DO
	#                  not proceed.
	$__first = GIT-Get-Root-Directory
	if ([string]::IsNullOrEmpty($__first)) {
		return 1
	}

	if ($__first -eq $__root) {
		return 1
	}


	# execute
	$__first = GIT-Get-First-Commit-ID
	if ([string]::IsNullOrEmpty($__first)) {
		return 1
	}

	$__process = OS-Exec "git" "reset --hard ${__first}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Exec "git" "clean -fd"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Is-Available {
	$__process = OS-Is-Command-Available "git"
	if ($__process -ne 0) {
		return 1
	}

	return 0
}




function GIT-Pull-To-Latest {
	# validate input
	$__process = GIT-Is-Available
	if ($__process -ne 0) {
		return 1
	}


	# execute
	$__process = OS-Exec "git" "pull"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Remove-Worktree {
	param (
		[string]$__destination
	)


	# validate input
	if ([string]::IsNullOrEmpty($__destination)) {
		return 1
	}

	$__process = GIT-Is-Available
	if ($__process -ne 0) {
		return 1
	}


	# execute
	$__process = OS-Exec "git" "worktree remove `"${__destination}`""
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Remove-Silently "${__destination}"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Setup-Worktree {
	param (
		[string]$__branch,
		[string]$__destination
	)


	# validate input
	if ([string]::IsNullOrEmpty($__branch) -or [string]::IsNullOrEmpty($__destination)) {
		return 1
	}

	$__process = GIT-Is-Available
	if ($__process -ne 0) {
		return 1
	}


	# execute
	$null = FS-Make-Directory "${__destination}"
	$__process = OS-Exec "git" "worktree add `"${__destination}`" `"${__branch}`""


	# report status
	if ($__process -eq 0) {
		return 0
	}

	return 1
}

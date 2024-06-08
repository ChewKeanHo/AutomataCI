# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




function GIT-At-Root-Repo {
	param(
		[string]$___directory
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___directory}") -eq 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = FS-Is-File "${___directory}\.git\config"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Autonomous-Commit {
	param(
		[string]$___tracker
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___tracker}") -eq 0) {
		return 1
	}

	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$___process = Invoke-Expression "git status --porcelain"
	if ($(STRINGS-Is-Empty "${___process}") -eq 0) {
		return 0 # nothing to commit
	}


	# execute
	$___process = OS-Exec "git" "add ."
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Exec "git" "commit -m 'automation: published as of ${___tracker}'"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Autonomous-Force-Commit {
	param(
		[string]$___tracker
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___tracker}") -eq 0) {
		return 1
	}

	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$___process = Invoke-Expression "git status --porcelain"
	if ($(STRINGS-Is-Empty "${___process}") -eq 0) {
		return 0 # nothing to commit
	}


	# execute
	$___process = OS-Exec "git" "add ."
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Exec "git" "commit -m 'Publish as of ${___tracker}'"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Change-Branch {
	param (
		[string]$___branch
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___branch}") -eq 0) {
		return 1
	}

	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "git" "checkout ${__branch}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Clone {
	param (
		[string]$___url,
		[string]$___name
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___url}") -eq 0) {
		return 1
	}

	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "$2") -ne 0) {
		$___process = FS-Is-File "${___name}"
		if ($___process -eq 0) {
			return 1
		}

		$___process = FS-Is-Directory "${___name}"
		if ($___process -eq 0) {
			return 2
		}
	}


	# execute
	if ($(STRINGS-Is-Empty "${___url}") -ne 0) {
		$___process = OS-Exec "git" "clone ${___url} ${___name}"
		if ($___process -ne 0) {
			return 1
		}
	} else {
		$___process = OS-Exec "git" "clone ${___url}"
		if ($___process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}




function GIT-Clone-Repo {
	param(
		[string]$___root,
		[string]$___relative_path,
		[string]$___current,
		[string]$___git_repo,
		[string]$___simulate,
		[string]$___label,
		[string]$___branch,
		[string]$___reset
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___root}") -eq 0) -or
		($(STRINGS-Is-Empty "${___relative_path}") -eq 0) -or
		($(STRINGS-Is-Empty "${___current}") -eq 0) -or
		($(STRINGS-Is-Empty "${___git_repo}") -eq 0) -or
		($(STRINGS-Is-Empty "${___label}") -eq 0)) {
		return 1
	}

	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___path = "${___root}\${___relative_path}"
	$null = FS-Make-Directory "${___path}"
	$___path = "${___path}\${___label}"

	$___process = FS-Is-Directory "${___path}"
	if ($___process -eq 0) {
		$null = Set-Location "${___path}"
		$___directory = GIT-Get-Root-Directory
		$null = Set-Location "${___current}"

		if ($___directory -eq $___root) {
			$null = FS-Remove-Silently "${___path}"
		}
	}

	if ($(STRINGS-Is-Empty "${___simulate}") -ne 0) {
		$null = FS-Make-Directory "${___path}"
		$null = Set-Location "${___path}"
		$null = OS-Exec "git" "init --initial-branch=main"
		$null = OS-Exec "git" "commit --allow-empty -m `"Initial Commit`""
		$null = Set-Location "${___current}"
		return 0
	} else {
		$null = Set-Location "$(Split-Path -Parent -Path "${___path}")"
		$___process = Git-Clone "${___git_repo}" "${___label}"
		switch ($___process) {
		{ $_ -in 2, 0 } {
			# Accepted
		} default {
			return 1
		}}
		$null = Set-Location "${___current}"
	}


	# switch branch if available
	if ($(STRINGS-Is-Empty "${___branch}") -ne 0) {
		$null = FS-Make-Directory "${___path}"
		$___process = GIT-Change-Branch "${___branch}"
		if ($___process -ne 0) {
			$null = Set-Location "${___current}"
			return 1
		}
		$null = Set-Location "${___current}"
	}


	# hard reset
	if ($(STRINGS-Is-Empty "${___reset}") -ne 0) {
		$null = FS-Make-Directory "${___path}"
		$___process = GIT-Hard-Reset-To-Init "${___root}"
		if ($___process -ne 0) {
			$null = Set-Location "${___current}"
			return 1
		}
		$null = Set-Location "${___current}"
	}


	# report status
	return 0
}




function GIT-Get-First-Commit-ID {
	# validate input
	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return ""
	}


	# execute
	return Invoke-Expression "git rev-list --max-parents=0 --abbrev-commit HEAD"
}




function GIT-Get-Latest-Commit-ID {
	# validate input
	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return ""
	}


	# execute
	return Invoke-Expression "git rev-parse HEAD"
}




function GIT-Get-Root-Directory {
	# validate input
	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return ""
	}
i

	# execute
	return Invoke-Expression "git rev-parse --show-toplevel"
}




function GIT-Hard-Reset-To-Init {
	param (
		[string]$___root
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___root}") -eq 0) {
		return 1
	}

	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# CVE-2023-42798 - Make sure the directory is not the same as the root
	#                  directory. If it does, bail out immediately and DO
	#                  not proceed.
	$___first = GIT-Get-Root-Directory
	if ($(STRINGS-Is-Empty "${___first}") -eq 0) {
		return 1
	}

	if ($___first -eq $___root) {
		return 1
	}


	# execute
	$___first = GIT-Get-First-Commit-ID
	if ($(STRINGS-Is-Empty "${___first}") -eq 0) {
		return 1
	}

	$___process = OS-Exec "git" "reset --hard ${___first}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Exec "git" "clean -fd"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Is-Available {
	# execute
	$___process = OS-Is-Command-Available "git"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Pull-To-Latest {
	# validate input
	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "git" "pull --rebase"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Push {
	param(
		[string]$___repo,
		[string]$___branch
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___repo}") -eq 0) -or
		($(STRINGS-Is-Empty "${___repo}") -eq 0)) {
		return 1
	}

	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "git" "push ${___repo} ${___branch}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Push-Specific {
	param(
		[string]$___workspace,
		[string]$___remote,
		[string]$___source,
		[string]$___target
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___workspace}") -eq 0) -or
		($(STRINGS-Is-Empty "${___remote}") -eq 0) -or
		($(STRINGS-Is-Empty "${___source}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target}") -eq 0)) {
		return 1
	}

	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___current_path = Get-Location
	$null = Set-Location -Path "${___workspace}"
	$___process = OS-Exec "git" "push -f `"${___remote}`" `"${___source}`":`"${___target}`""
	$null = Set-Location -Path "${___current_path}"
	$null = Remove-Variable -Name ___current_path
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Remove-Worktree {
	param (
		[string]$___destination
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___destination}") -eq 0) {
		return 1
	}

	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "git" "worktree remove `"${___destination}`""
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Remove-Silently "${___destination}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Setup-Worktree {
	param (
		[string]$___branch,
		[string]$___destination
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___branch}") -eq 0) -or
		($(STRINGS-Is-Empty "${___branch}") -eq 0)) {
		return 1
	}

	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$null = FS-Make-Directory "${___destination}"
	$___process = OS-Exec "git" "worktree add `"${___destination}`" `"${___branch}`""
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GIT-Setup-Workspace-Bare {
	param(
		[string]$___remote,
		[string]$___branch,
		[string]$___destination
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___remote}") -eq 0) -or
		($(STRINGS-Is-Empty "${___branch}") -eq 0) -or
		($(STRINGS-Is-Empty "${___destination}") -eq 0)) {
		return 1
	}

	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___url = "$(GIT-Get-Remote-URL "${___remote}")"
	if ($(STRINGS-Is-Empty "${___url}") -eq 0) {
		return 1
	}

	$null = FS-Remake-Directory "${___destination}"
	$___current_path = Get-Location
	$null = Set-Location -Path "${___workspace}"

	$___process = OS-Exec "git" "init"
	if ($___process -ne 0) {
		$null = Set-Location -Path "${___current_path}"
		$null = Remove-Variable -Name ___current_path
		return 1
	}

	$___process = OS-Exec "git" "remote add `"${___remote}`" `"${___url}`""
	if ($___process -ne 0) {
		$null = Set-Location -Path "${___current_path}"
		$null = Remove-Variable -Name ___current_path
		return 1
	}

	$___process = OS-Exec "git" "checkout --orphan `"${___branch}`""
	if ($___process -ne 0) {
		$null = Set-Location -Path "${___current_path}"
		$null = Remove-Variable -Name ___current_path
		return 1
	}

	$null = Set-Location -Path "${___current_path}"
	$null = Remove-Variable -Name ___current_path


	# report status
	return 0
}

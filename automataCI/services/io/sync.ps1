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




# To use:
#   $ SYNC-Parallel-Exec "dir " "$(Get-Location)/parallel.txt" "/tmp/parallel" "4" Init-Fx
#
#   The receiving parameters to the __parallel_command would be each line of the
#   "$(Get-Location)/parallel.txt", such that the above command will be similar
#   as the following with the $__line is being expanded:
#                            $ [COMMAND] ${__line}
#                            $ dir ${__line}
#
#   The __parallel_command can accept function. It is **strongly recommended**
#   to feed a wrapper function such that each line is a clean command:
#       function Function-Name {
#               param (
#                       [string]$__line
#               )
#
#
#               # some tasks in your thread
#               ...
#
#
#               # execute
#               $__output = Invoke-Expression "${__line}"
#               if ($LASTEXITCODE -ne 0); then
#                       return 1 # signal an error has occured
#               fi
#
#               ... process $__output ...
#
#
#               # report status
#               return 0 # signal a successful execution
#       }
#
#       function Init-Fx {
#               # some execution to initialize the thread from scratch
#       }
#
#       # call the parallel exec
#       SYNC-Parallel-Exec "Function-Name" `
#                          "$(Get-Location)/parallel.txt" `
#                          "/tmp/parallel" `
#                          "4" `
#                          Init-Fx
#
#
#   The control file must not have any comment and each line must be the capable
#   of being executed in a single thread. Likewise, when feeding a function,
#   each line can be a fully processed and executable command on its own.
#
#   The __parallel_command **MUST** return the following return code:
#     0 = signal the task execution is done and completed successfully.
#     1 = signal the task execution has error. This terminates the entire run.
function SYNC-Parallel-Exec {
	param(
		[string]$__parallel_command,
		[string]$__parallel_control,
		[string]$__parallel_directory,
		[string]$__parallel_available,
		[string]$__parallel_initializer
	)


	# validate input
	if ([string]::IsNullOrEmpty($__parallel_command)) {
		return 1
	}

	if ([string]::IsNullOrEmpty($__parallel_initializer)) {
		return 1
	}

	$__process = [System.Security.Cryptography.SHA256]::Create("SHA256")
	if (-not $__process) {
		return 1
	}

	if ([string]::IsNullOrEmpty($__parallel_control) -or
		(-not (Test-Path -Path "${__parallel_control}"))) {
		return 1
	}

	if ([string]::IsNullOrEmpty($__parallel_available)) {
		$__parallel_available = [System.Environment]::ProcessorCount
	}

	if ($__parallel_available -le 0) {
		$__parallel_available = 1
	}

	if ([string]::IsNullOrEmpty($__parallel_directory)) {
		$__parallel_directory = Split-Path -Path "${__parallel_control}" -Parent
	}

	if (-not (Test-Path -Path "${__parallel_directory}" -PathType Container)) {
		return 1
	}


	# execute
	$__parallel_directory = "${__parallel_directory}\flags"
	$__parallel_total = 0


	# scan total tasks
	foreach ($__line in (Get-Content "${__parallel_control}")) {
		$__parallel_total += 1
	}


	# end the execution if no task is available
	if ($__parallel_total -le 0) {
		return 0
	}


	# run singularly when parallelism is unavailable or has only 1 task
	if (($__parallel_available -le 1) -or ($__parallel_total -eq 1)) {
		foreach ($__line in (Get-Content "${__parallel_control}")) {
			$null = Invoke-Expression "${__parallel_command} ${__line}"
			if ($LASTEXITCODE -ne 0) {
				return 1
			}
		}

		# report status
		return 0
	}


	# run parallely
	$__jobs = @()
	foreach ($__line in (Get-Content "${__parallel_control}")) {
		$__jobs += Start-ThreadJob -InitializationScript {
			$__parallel_initializer
		} -ScriptBlock {
			$null = Invoke-Expression "${using:__line}"
			if ($LASTEXITCODE -eq 0) {
				return 0
			}

			return 1
		}
	}

	$null = Wait-Job -Job $__jobs

	foreach ($__job in $__jobs) {
		Receive-Job -Job $__job
	}


	# report status
	return 0
}

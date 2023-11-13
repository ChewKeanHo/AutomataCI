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
#   $ SYNC-Parallel-Exec ${function:Function-Name}.ToString() `
#                          "$(Get-Location)\parallel.txt" `
#                          ".\tmp\parallel" `
#                          "$([System.Environment]::ProcessorCount)"
#
#   The __parallel_command accepts a wrapper function as shown above. Here is an
#   example to construct a simple parallelism executions:
#       function Function-Name {
#               param (
#                       [string]$__line
#               )
#
#
#               # initialize and import libraries from scratch
#               ...
#
#
#               # break line into multiple parameters (delimiter = '|')
#               $__list = $__line -split "\|"
#               $__arg1 = $__list[1]
#               $__arg2 = $__list[2]
#               ...
#
#
#
#               # some tasks in your thread
#               ...
#
#
#               # execute
#               ...
#
#
#               # report status
#               return 0 # signal a successful execution
#       }
#
#
#       # calling the parallel exec function
#       SYNC-Parallel-Exec ${function:Function-Name}.ToString() `
#                          "$(Get-Location)\parallel.txt" `
#                          ".\tmp\parallel" `
#                          "$([System.Environment]::ProcessorCount)"
#
#
#   The control file must not have any comment and each line must be the capable
#   of being executed in a single thread. Likewise, when feeding a function,
#   each line is a long string with your own separator. You will have to break
#   it inside your wrapper function.
#
#   The __parallel_command **MUST** return **ONLY** the following return code:
#     0 = signal the task execution is done and completed successfully.
#     1 = signal the task execution has error. This terminates the entire run.
function SYNC-Parallel-Exec {
	param(
		[string]$__parallel_command,
		[string]$__parallel_control,
		[string]$__parallel_directory,
		[string]$__parallel_available
	)


	# validate input
	if ([string]::IsNullOrEmpty($__parallel_command)) {
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
		# prepare
		${function:SYNC-Run} = ${__parallel_command}


		# execute
		foreach ($__line in (Get-Content "${__parallel_control}")) {
			$__process = SYNC-Run "${__line}"
			if ($__process -ne 0) {
				return 1
			}
		}


		# report status
		return 0
	}


	# run in parallel
	$__jobs = @()
	foreach ($__line in (Get-Content "${__parallel_control}")) {
		$__jobs += Start-ThreadJob -ScriptBlock {
			# prepare
			${function:SYNC-Run} = ${using:__parallel_command}


			# execute
			$__process = SYNC-Run "${using:__line}"
			if ($__process -ne 0) {
				return 1
			}


			# report status
			return 0
		}
	}

	$null = Wait-Job -Job $__jobs
	foreach ($__job in $__jobs) {
		$__process = Receive-Job -Job $__job
		if ($__process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}




# To use:
#   $ SYNC-Series-Exec ${function:Function-Name}.ToString() "$(Get-Location)\parallel.txt"
#
#   The __series_command accepts a wrapper function as shown above. Here is an
#   example to construct a simple parallelism executions:
#       function Function-Name {
#               param (
#                       [string]$__line
#               )
#
#
#               # initialize and import libraries from scratch
#               ...
#
#
#               # break line into multiple parameters (delimiter = '|')
#               $__list = $__line -split "\|"
#               $__arg1 = $__list[1]
#               $__arg2 = $__list[2]
#               ...
#
#
#
#               # some tasks in your thread
#               ...
#
#
#               # execute
#               ...
#
#
#               # report status
#               return 0 # signal a successful execution
#       }
#
#
#       # calling the parallel exec function
#       SYNC-Series-Exec ${function:Function-Name}.ToString() "$(Get-Location)\parallel.txt"
#
#
#   The control file must not have any comment and each line must be the capable
#   of being executed in a single thread. Likewise, when feeding a function,
#   each line is a long string with your own separator. You will have to break
#   it inside your wrapper function.
#
#   The __series_command **MUST** return **ONLY** the following return code:
#     0 = signal the task execution is done and completed successfully.
#     1 = signal the task execution has error. This terminates the entire run.
function SYNC-Series-Exec {
	param(
		[string]$__series_command,
		[string]$__series_control
	)


	# validate input
	if ([string]::IsNullOrEmpty($__series_command)) {
		return 1
	}

	if ([string]::IsNullOrEmpty($__series_control) -or
		(-not (Test-Path -Path "${__series_control}"))) {
		return 1
	}


	# execute
	${function:SYNC-Run} = ${__series_command}
	foreach ($__line in (Get-Content "${__series_control}")) {
		$__process = SYNC-Run "${__line}"
		if ($__process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}

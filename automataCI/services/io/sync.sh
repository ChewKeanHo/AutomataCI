#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# To use:
#   $ SYNC::parallel_exec "function_name" "${PWD}/parallel.txt" "/tmp/parallel" "4"
#
#   The __parallel_command accepts a wrapper function as shown above. Here is an
#   example to construct a simple parallelism executions:
#       function_name() {
#               #__line="$1"
#
#
#               # break line into multiple parameters (delimiter = '|')
#               __line="${1%|*}"
#
#               __last="${__line##*|}"
#               __line="${__line%|*}"
#
#               __2nd_last="${__line##*|}"
#               __line="${__line%|*}"
#
#               ...
#
#
#               # some tasks in your thread
#               ...
#
#
#               # execute
#               $@
#               if [ $? -ne 0 ]; then
#                       return 1 # signal an error has occured
#               fi
#
#
#               # report status
#               return 0 # signal a successful execution
#       }
#
#
#       # call the parallel exec
#       SYNC::parallel_exec "function_name" "${PWD}/parallel.txt" "/tmp/parallel" "4"
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
SYNC::parallel_exec() {
        __parallel_command="$1"
        __parallel_control="$2"
        __parallel_directory="$3"
        __parallel_available="$4"


        # validate input
        if [ -z "$__parallel_command" ]; then
                return 1
        fi

        if [ -z "$(type -t shasum)" ]; then
                return 1
        fi

        if [ -z "$__parallel_control" ] || [ ! -f "$__parallel_control" ]; then
                return 1
        fi

        if [ -z "$__parallel_available" ]; then
                __parallel_available=$(getconf _NPROCESSORS_ONLN)
        fi

        if [ $__parallel_available -le 0 ]; then
                __parallel_available=1
        fi

        if [ -z "$__parallel_directory" ]; then
                __parallel_directory="${__parallel_control%/*}"
        fi

        if [ ! -d "$__parallel_directory" ]; then
                return 1
        fi


        # execute
        __parallel_directory="${__parallel_directory}/flags"
        __parallel_total=0
        __parallel_current=0
        __parallel_working=0
        __parallel_error=0
        __parallel_done=0


        # scan total tasks
        __old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                __parallel_total=$(($__parallel_total + 1))
        done < "$__parallel_control"
        IFS="$__old_IFS" && unset __old_IFS


        # end the execution if no task is available
        if [ $__parallel_total -le 0 ]; then
                return 0
        fi


        # run singularly when parallelism is unavailable or has only 1 task
        if [ $__parallel_available -le 1 ] || [ $__parallel_total -eq 1 ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        "$__parallel_command" "$__line"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                done < "$__parallel_control"
                IFS="$__old_IFS" && unset __old_IFS

                # report status
                return 0
        fi


        # run parallely
        rm -rf "$__parallel_directory" &> /dev/null
        mkdir -p "$__parallel_directory" &> /dev/null
        while [ $__parallel_done -ne $__parallel_total ]; do
                __parallel_done=0
                __parallel_current=0
                __parallel_working=0

                # scan state
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __parallel_flag="$(printf -- "%b" "$__line" | shasum -a 256)"
                        __parallel_flag="${__parallel_directory}/${__parallel_flag%% *}"

                        # break if error flag is found
                        if [ -d "${__parallel_flag}.parallel-error" ]; then
                                __parallel_error=$(($__parallel_error + 1))
                                continue
                        fi

                        # skip if working flag is found
                        if [ -d "${__parallel_flag}.parallel-working" ]; then
                                __parallel_working=$(($__parallel_working + 1))
                                __parallel_current=$(($__parallel_current + 1))
                                continue
                        fi

                        # break entire scan when run is completed
                        if [ $__parallel_done -eq $__parallel_total ]; then
                                break
                        fi

                        # skip if done flag is found
                        if [ -d "${__parallel_flag}.parallel-done" ]; then
                                __parallel_done=$(($__parallel_done + 1))
                                __parallel_current=$(($__parallel_current + 1))
                                continue
                        fi

                        # it is a working state
                        if [ $__parallel_working -lt $__parallel_available ]; then
                                # secure parallel lock
                                mkdir -p "${__parallel_flag}.parallel-working"
                                __parallel_working=$(($__parallel_working + 1))

                                # initiate parallel execution
                                {
                                        "$__parallel_command" $__line

                                        # release lock
                                        case $? in
                                        0)
                                                mkdir -p "${__parallel_flag}.parallel-done"
                                                ;;
                                        *)
                                                mkdir -p "${__parallel_flag}.parallel-error"
                                                ;;
                                        esac
                                        rm -rf "${__parallel_flag}.parallel-working" \
                                                &> /dev/null
                                } &
                        fi
                        __parallel_current=$(($__parallel_current + 1))
                done < "$__parallel_control"
                IFS="$__old_IFS" && unset __old_IFS

                # stop the entire operation if error is detected + no more working tasks
                if [ $__parallel_error -gt 0 -a $__parallel_working -eq 0 ]; then
                        return 1
                fi
        done


        # report status
        return 0
}




# To use:
#   $ SYNC::series_exec "function_name" "${PWD}/parallel.txt"
#
#   The __series_command accepts a wrapper function as shown above. Here is an
#   example to construct a simple series of executions:
#       function_name() {
#               #__line="$1"
#
#
#               # break line into multiple parameters (delimiter = '|')
#               __line="${1%|*}"
#
#               __last="${__line##*|}"
#               __line="${__line%|*}"
#
#               __2nd_last="${__line##*|}"
#               __line="${__line%|*}"
#
#               ...
#
#
#               # some tasks in your thread
#               ...
#
#
#               # execute
#               $@
#               if [ $? -ne 0 ]; then
#                       return 1 # signal an error has occured
#               fi
#
#
#               # report status
#               return 0 # signal a successful execution
#       }
#
#
#       # call the series exec
#       SYNC::series_exec "function_name" "${PWD}/parallel.txt"
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
SYNC::series_exec() {
        __series_command="$1"
        __series_control="$2"


        # validate input
        if [ -z "$__series_command" ]; then
                return 1
        fi

        if [ -z "$__series_control" ] || [ ! -f "$__series_control" ]; then
                return 1
        fi


        # execute
        __old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                "$__series_command" "$__line"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done < "$__series_control"
        IFS="$__old_IFS" && unset __old_IFS


        # report status
        return 0
}

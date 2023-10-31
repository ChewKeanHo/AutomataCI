#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/strings.sh"




# validate input
OS::print_status info "Validating CI job...\n"
if [ -z "$PROJECT_CI_JOB" ]; then
        OS::print_status info "Validation failed.\n"
        return 1
fi




# execute ANGULAR if set
if [ ! -z "$PROJECT_ANGULAR" ]; then
        __recipe="$(STRINGS::to_lowercase "$PROJECT_CI_JOB")_unix-any.sh"
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_ANGULAR}/${PROJECT_PATH_CI}/${__recipe}"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info "ANGULAR tech detected. Running job recipe: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Run failed.\n"
                        return 1
                fi
        fi
fi




# execute C if set
if [ ! -z "$PROJECT_C" ]; then
        __recipe="$(STRINGS::to_lowercase "$PROJECT_CI_JOB")_unix-any.sh"
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_C}/${PROJECT_PATH_CI}/${__recipe}"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info "C tech detected. Running job recipe: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Run failed.\n"
                        return 1
                fi
        fi
fi




# execute GO if set
if [ ! -z "$PROJECT_GO" ]; then
        __recipe="$(STRINGS::to_lowercase "$PROJECT_CI_JOB")_unix-any.sh"
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_GO}/${PROJECT_PATH_CI}/${__recipe}"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info "Go tech detected. Running job recipe: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Run failed.\n"
                        return 1
                fi
        fi
fi




# execute NIM if set
if [ ! -z "$PROJECT_NIM" ]; then
        __recipe="$(STRINGS::to_lowercase "$PROJECT_CI_JOB")_unix-any.sh"
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_NIM}/${PROJECT_PATH_CI}/${__recipe}"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info "NIM tech detected. Running job recipe: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Run failed.\n"
                        return 1
                fi
        fi
fi




# execute PYTHON if set
if [ ! -z "$PROJECT_PYTHON" ]; then
        __recipe="$(STRINGS::to_lowercase "$PROJECT_CI_JOB")_unix-any.sh"
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/${PROJECT_PATH_CI}/${__recipe}"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info \
                        "Python tech detected. Running job recipe: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Run failed.\n"
                        return 1
                fi
        fi
fi




# execute RUST if set
if [ ! -z "$PROJECT_RUST" ]; then
        __recipe="$(STRINGS::to_lowercase "$PROJECT_CI_JOB")_unix-any.sh"
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_RUST}/${PROJECT_PATH_CI}/${__recipe}"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info "RUST tech detected. Running job recipe: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Run failed.\n"
                        return 1
                fi
        fi
fi




# execute baseline as last
__recipe="$(STRINGS::to_lowercase "$PROJECT_CI_JOB")_unix-any.sh"
__recipe="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/${__recipe}"
FS::is_file "$__recipe"
if [ $? -eq 0 ]; then
        OS::print_status info "Baseline source detected. Running job recipe: ${__recipe}\n"
        . "$__recipe"
        if [ $? -ne 0 ]; then
                OS::print_status error "Run failed.\n"
                return 1
        fi
fi




# report status
OS::print_status success "\n\n"
return 0

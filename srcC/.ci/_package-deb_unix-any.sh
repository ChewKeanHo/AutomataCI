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




PACKAGE::assemble_deb_content() {
        __target="$1"
        __directory="$2"
        __target_name="$3"
        __target_os="$4"
        __target_arch="$5"


        # validate target before job
        if [ $(FS::is_target_a_source "$__target") -eq 0 ]; then
                return 10
        elif [ $(FS::is_target_a_library "$__target") -eq 0 ]; then
                # copy main libary
                # TIP: (1) usually is: usr/local/lib
                #      (2) please avoid: lib/, lib{TYPE}/ usr/lib/, and usr/lib{TYPE}/
                __filepath="${__directory}/data/usr/local/lib/${PROJECT_SKU}"
                __filepath="${__filepath}/lib${PROJECT_SKU}.a"
                OS::print_status info "copying ${__target} to ${__filepath}\n"
                FS::make_housing_directory "$__filepath"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                FS::copy_file "$1" "$__filepath"
                if [ $? -ne 0 ]; then
                        OS::print_status error "copy failed.\n"
                        return 1
                fi
        else
                case "$__target_os" in
                windows)
                        __dest="${__directory}/${PROJECT_SKU}.exe"
                        ;;
                *)
                        __dest="${__directory}/${PROJECT_SKU}"
                        ;;
                esac

                # copy main program
                # TIP: (1) usually is: usr/local/bin or usr/local/sbin
                #      (2) please avoid: bin/, usr/bin/, sbin/, and usr/sbin/
                __filepath="${__directory}/data/usr/local/bin/${PROJECT_SKU}"
                OS::print_status info "copying $__target to ${__filepath}/\n"
                FS::make_housing_directory "$__filepath"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                FS::copy_file "$1" "$__filepath"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        # OPTIONAL (overrides): copy usr/share/docs/${PROJECT_SKU}/changelog.gz
        # OPTIONAL (overrides): copy usr/share/docs/${PROJECT_SKU}/copyright.gz
        # OPTIONAL (overrides): copy usr/share/man/man1/${PROJECT_SKU}.1.gz
        # OPTIONAL (overrides): generate ${__directory}/control/md5sum
        # OPTIONAL (overrides): generate ${__directory}/control/control


        # report status
        return 0
}

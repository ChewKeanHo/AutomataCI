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




# (0) initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please source from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




PACKAGE::assemble_archive_content() {
        __target="$1"
        __directory="$2"
        __target_name="$3"
        __target_os="$4"
        __target_arch="$5"


        # copy main program
        OS::print_status info "copying $__target to $__directory\n"
        case "$__target_os" in
        windows)
                FS::copy_file "$__target" "${__directory}/${PROJECT_SKU}.exe"
                ;;
        *)
                FS::copy_file "$__target" "${__directory}/${PROJECT_SKU}"
                ;;
        esac
        if [ $? -ne 0 ]; then
                unset __target \
                        __directory \
                        __target_name \
                        __target_os \
                        __target_arch
                return 1
        fi


        # copy user guide
        __target="${PROJECT_PATH_ROOT}/USER-GUIDES-EN.pdf"
        OS::print_status info "copying $__target to $__directory\n"
        FS::copy_file "$__target" "${__directory}/."
        if [ $? -ne 0 ]; then
                unset __target \
                        __directory \
                        __target_name \
                        __target_os \
                        __target_arch
                return 1
        fi


        # copy license file
        __target="${PROJECT_PATH_ROOT}/LICENSE-EN.pdf"
        OS::print_status info "copying $__target to $__directory\n"
        FS::copy_file "$__target" "${__directory}/."
        if [ $? -ne 0 ]; then
                unset __target \
                        __directory \
                        __target_name \
                        __target_os \
                        __target_arch
                return 1
        fi


        # report status
        unset __target \
                __directory \
                __target_name \
                __target_os \
                __target_arch
        return 0
}




PACKAGE::assemble_deb_content() {
        __target="$1"
        __directory="$2"
        __target_name="$3"
        __target_os="$4"
        __target_arch="$5"




        # copy main program
        # TIP: (1) usually is: usr/local/bin or usr/local/sbin
        #      (2) please avoid: bin/, usr/bin/, sbin/, and usr/sbin/
        __filepath="${__directory}/data/usr/local/bin/${PROJECT_SKU}"
        OS::print_status info "copying $__target to ${__filepath}/\n"
        FS::make_directory "${__filepath%/*}"
        if [ $? -ne 0 ]; then
                unset __filepath \
                        __target \
                        __directory \
                        __target_name \
                        __target_os \
                        __target_arch
                return 1
        fi

        __target="$1"
        FS::copy_file "$__target" "$__filepath"
        if [ $? -ne 0 ]; then
                unset __filepath \
                        __target \
                        __directory \
                        __target_name \
                        __target_os \
                        __target_arch
                return 1
        fi


        # OPTIONAL (overrides): copy usr/share/docs/${PROJECT_SKU}/changelog.gz
        # OPTIONAL (overrides): copy usr/share/docs/${PROJECT_SKU}/copyright.gz
        # OPTIONAL (overrides): copy usr/share/man/man1/${PROJECT_SKU}.1.gz
        # OPTIONAL (overrides): generate ${directory}/control/md5sum
        # OPTIONAL (overrides): generate ${directory}/control/control


        # report status
        unset __filepath \
                __target \
                __directory \
                __target_name \
                __target_os \
                __target_arch
        return 0
}




PACKAGE::assemble_flatpak_content() {
        __target="$1"
        __directory="$2"
        __target_name="$3"
        __target_os="$4"
        __target_arch="$5"


        # copy main program
        __target="$1"
        __filepath="${__directory}/${PROJECT_SKU}"
        OS::print_status info "copying $__target to ${__filepath}\n"
        FS::copy_file "$__target" "$__filepath"
        if [ $? -ne 0 ]; then
                unset __filepath \
                        __target \
                        __directory \
                        __target_name \
                        __target_os \
                        __target_arch
                return 1
        fi


        # copy icon.svg
        __target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/logos/icon.svg"
        __filepath="${__directory}/icon.svg"
        OS::print_status info "copying $__target to ${__filepath}\n"
        FS::copy_file "$__target" "$__filepath"
        if [ $? -ne 0 ]; then
                unset __filepath \
                        __target \
                        __directory \
                        __target_name \
                        __target_os \
                        __target_arch
                return 1
        fi


        # copy icon-48x48.png
        __target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/logos/icon-48x48.png"
        __filepath="${__directory}/icon-48x48.png"
        OS::print_status info "copying $__target to ${__filepath}\n"
        FS::copy_file "$__target" "$__filepath"
        if [ $? -ne 0 ]; then
                unset __filepath \
                        __target \
                        __directory \
                        __target_name \
                        __target_os \
                        __target_arch
                return 1
        fi


        # copy icon-128x128.png
        __target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/logos/icon-128x128.png"
        __filepath="${__directory}/icon-128x128.png"
        OS::print_status info "copying $__target to ${__filepath}\n"
        FS::copy_file "$__target" "$__filepath"
        if [ $? -ne 0 ]; then
                unset __filepath \
                        __target \
                        __directory \
                        __target_name \
                        __target_os \
                        __target_arch
                return 1
        fi


        # OPTIONAL (overrides): copy manifest.yml or manifest.json
        # OPTIONAL (overrides): copy appdata.xml


        # report status
        unset __filepath \
                __target \
                __directory \
                __target_name \
                __target_os \
                __target_arch
        return 0
}

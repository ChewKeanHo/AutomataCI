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




PACKAGE::assemble_rpm_content() {
        __target="$1"
        __directory="$2"
        __target_name="$3"
        __target_os="$4"
        __target_arch="$5"

        # validate target before job
        FS::is_target_a_source "$__target"
        if [ $? -eq 0 ]; then
                return 10
        fi

        # copy main program
        # TIP: (1) copy all files into "${__directory}/BUILD" directory.
        __filepath="${__directory}/BUILD/${PROJECT_SKU}"
        OS::print_status info "copying $__target to ${__filepath}\n"
        FS::make_housing_directory "$__filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::copy_file "$1" "$__filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # generate AutomataCI's required RPM spec instructions (INSTALL)
        FS::write_file "${__directory}/SPEC_INSTALL" "\
install --directory %{buildroot}/usr/local/bin
install -m 0755 ${PROJECT_SKU} %{buildroot}/usr/local/bin

install --directory %{buildroot}/usr/local/share/doc/${PROJECT_SKU}/
install -m 644 copyright %{buildroot}/usr/local/share/doc/${PROJECT_SKU}/

install --directory %{buildroot}/usr/local/share/man/man1/
install -m 644 ${PROJECT_SKU}.1.gz %{buildroot}/usr/local/share/man/man1/
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # generate AutomataCI's required RPM spec instructions (FILES)
        FS::write_file "${__directory}/SPEC_FILES" "\
/usr/local/bin/${PROJECT_SKU}
/usr/local/share/doc/${PROJECT_SKU}/copyright
/usr/local/share/man/man1/${PROJECT_SKU}.1.gz
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # OPTIONAL (overrides): ${__directory}/BUILD/copyright.gz
        # OPTIONAL (overrides): ${__directory}/BUILD/man.1.gz
        # OPTIONAL (overrides): ${__directory}/SPECS/${PROJECT_SKU}.spec

        # report status
        return 0
}

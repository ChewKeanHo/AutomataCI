#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/rust.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




RELEASE_Run_CARGO() {
        _target="$1"


        # validate input
        RUST_Crate_Is_Valid "$_target"
        if [ $? -ne 0 ]; then
                return 0
        fi

        I18N_Check_Availability "RUST"
        RUST_Activate_Local_Environment
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # execute
        I18N_Publish "CARGO"
        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                I18N_Simulate_Publish "CARGO"
        else
                I18N_Check_Login "CARGO"
                RUST_Cargo_Login
                if [ $? -ne 0 ]; then
                        I18N_Check_Failed
                        I18N_Logout "CARGO"
                        RUST_Cargo_Logout
                        return 1
                fi

                RUST_Cargo_Release_Crate "$_target"
                if [ $? -ne 0 ]; then
                        I18N_Publish_Failed
                        I18N_Logout "CARGO"
                        RUST_Cargo_Logout
                        return 1
                fi

                I18N_Logout "CARGO"
                RUST_Cargo_Logout
                if [ $? -ne 0 ]; then
                        I18N_Logout_Failed
                        return 1
                fi
        fi

        I18N_Clean "$_target"
        FS_Remove_Silently "$_target"


        # report status
        return 0
}

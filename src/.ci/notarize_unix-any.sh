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




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/crypto/notary.sh"




NOTARIZE_Certify() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate project
        if [ $(FS_Is_Target_A_Source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Library "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_WASM_JS "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_WASM "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Chocolatey "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Homebrew "$_target") -eq 0 ]; then
                return 10 # not applicable
        fi


        # notarize
        case "$_target_os" in
        darwin)
                if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                        return 12
                fi

                NOTARY_Apple_Is_Available
                if [ $? -ne 0 ]; then
                        return 11
                fi

                _dest="$(FS_Get_Directory "$_target")"
                _dest="${_dest}/${_target_name}-signed_${_target_os}-${_target_arch}"
                NOTARY_Sign_Apple "$_dest" "$_target"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                ;;
        windows)
                if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                        return 12
                fi

                NOTARY_Microsoft_Is_Available
                if [ $? -ne 0 ]; then
                        return 11
                fi

                _dest="$(FS_Get_Directory "$_target")"
                _dest="${_dest}/${_target_name}-signed_${_target_os}-${_target_arch}.exe"
                NOTARY_Sign_Microsoft \
                        "$_dest" \
                        "$_target" \
                        "$PROJECT_CONTACT_NAME" \
                        "$PROJECT_CONTACT_WEBSITE"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                ;;
        *)
                return 10 # not applicable
                ;;
        esac


        # report status
        return 0
}

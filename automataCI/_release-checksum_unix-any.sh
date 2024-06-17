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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/crypto/gpg.sh"
. "${LIBS_AUTOMATACI}/services/checksum/shasum.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




RELEASE_Conclude_CHECKSUM() {
        #__repo_directory="$1"


        # execute
        __sha256_file="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/releaser-sha256.txt"
        FS_Remove_Silently "$__sha256_file"

        __sha512_file="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/releaser-sha512.txt"
        FS_Remove_Silently "$__sha512_file"

        __sha256_target="${PROJECT_SKU}-sha256_${PROJECT_VERSION}.txt"
        __sha256_target="${1}/${__sha256_target}"
        FS_Remove_Silently "$__sha256_target"

        __sha512_target="${PROJECT_SKU}-sha512_${PROJECT_VERSION}.txt"
        __sha512_target="${1}/${__sha512_target}"
        FS_Remove_Silently "$__sha512_target"


        # gpg sign all packages
        GPG_Is_Available "$PROJECT_GPG_ID"
        if [ $? -eq 0 ]; then
                __keyfile="${PROJECT_SKU}-gpg_${PROJECT_VERSION}.keyfile"
                __keyfile="${1}/${__keyfile}"

                I18N_Publish "$__keyfile"
                FS_Remove_Silently "$__keyfile"
                if [ $(OS_Is_Run_Simulated) -ne 0 ]; then
                        GPG_Export_Public_Key "$__keyfile" "$PROJECT_GPG_ID"
                        if [ $? -ne 0 ]; then
                                I18N_Publish_Failed
                                return 1
                        fi
                else
                        I18N_Simulate_Publish "$__keyfile"
                fi

                # gpg sign all packages
                for TARGET in "$1"/*; do
                        if [ ! "${TARGET%%.asc*}" = "$TARGET" ]; then
                                continue # it's a gpg cert
                        fi

                        if [ ! "${TARGET%%.gpg*}" = "$TARGET" ]; then
                                continue # it's a gpg keyfile or cert
                        fi

                        I18N_Sign "$TARGET" "GPG"
                        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                                I18N_Simulate_Notarize "$TARGET"
                                continue
                        fi

                        FS_Remove_Silently "${TARGET}.asc"
                        GPG_Detach_Sign_File "${TARGET}.asc" "$TARGET" "$PROJECT_GPG_ID"
                        if [ $? -ne 0 ]; then
                                I18N_Sign_Failed
                                return 1
                        fi
                done
        fi


        # shasum all files
        for TARGET in "$1"/*; do
                FS_Is_Directory "$TARGET"
                if [ $? -eq 0 ]; then
                        I18N_Is_Directory_Skipped "$TARGET"
                        continue
                fi

                if [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_SHA256") -ne 0 ]; then
                        I18N_Checksum "$TARGET" "SHA256"
                        __value="$(SHASUM_Create_From_File "$TARGET" "256")"
                        if [ $(STRINGS_Is_Empty "${__value}") -eq 0 ]; then
                                I18N_Checksum_Failed
                                return 1
                        fi

                        FS_Append_File \
                                "$__sha256_file" \
                                "${__value}  $(FS_Get_File "$TARGET")\n"
                        if [ $? -ne 0 ]; then
                                I18N_Checksum_Failed
                                return 1
                        fi
                fi


                if [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_SHA512") -ne 0 ]; then
                        I18N_Checksum "$TARGET" "SHA512"
                        __value="$(SHASUM_Create_From_File "$TARGET" "512")"
                        if [ $(STRINGS_Is_Empty "$__value") -eq 0 ]; then
                                I18N_Checksum_Failed
                                return 1
                        fi

                        FS_Append_File \
                                "$__sha512_file" \
                                "${__value}  $(FS_Get_File "$TARGET")\n"
                        if [ $? -ne 0 ]; then
                                I18N_Checksum_Failed
                                return 1
                        fi
                fi
        done


        FS_Is_File "$__sha256_file"
        if [ $? -eq 0 ]; then
                I18N_Conclude "$__sha256_target"
                FS_Move "$__sha256_file" "$__sha256_target"
                if [ $? -ne 0 ]; then
                        I18N_Conclude_Failed
                        return 1
                fi
        fi


        FS_Is_File "$__sha512_file"
        if [ $? -eq 0 ]; then
                I18N_Conclude "$__sha512_target"
                FS_Move "$__sha512_file" "$__sha512_target"
                if [ $? -ne 0 ]; then
                        I18N_Conclude_Failed
                        return 1
                fi
        fi


        # report status
        return 0
}




RELEASE_Initiate_CHECKSUM() {
        # execute
        I18N_Check_Availability "SHASUM"
        SHASUM_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi

        I18N_Check_Availability "GPG"
        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                I18N_Simulate_Available "GPG"
        else
                GPG_Is_Available "$PROJECT_GPG_ID"
                if [ $? -ne 0 ]; then
                        I18N_Check_Failed
                        return 1
                fi
        fi


        # report status
        return 0
}

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
        >&2 printf "[ ERROR ] - Please run from autoamtaCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/copyright.sh"
. "${LIBS_AUTOMATACI}/services/compilers/deb.sh"
. "${LIBS_AUTOMATACI}/services/compilers/manual.sh"




PACKAGE_Assemble_DEB_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"
        _changelog="$6"


        # validate target before job
        case "$_target_os" in
        android|ios|js|illumos|plan9|wasip1)
                return 10 # not supported in apt ecosystem yet
                ;;
        windows)
                return 10 # not applicable
                ;;
        *)
                ;;
        esac

        case "$_target_arch" in
        avr|wasm)
                return 10 # not applicable
                ;;
        *)
                ;;
        esac

        _gpg_keyring="$PROJECT_SKU"
        _package="$PROJECT_SKU"
        if [ $(FS_Is_Target_A_Source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Docs "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Library "$_target") -eq 0 ]; then
                # copy main libary
                # TIP: (1) usually is: usr/local/lib
                #      (2) please avoid: lib/, lib{TYPE}/ usr/lib/, and usr/lib{TYPE}/
                ___dest="${_directory}/data/usr/local/lib/${PROJECT_SKU}"

                I18N_Copy "$_target" "$___dest"
                FS_Make_Directory "$___dest"
                FS_Copy_File "$_target" "$___dest"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi

                _gpg_keyring="lib$PROJECT_SKU"
                _package="lib$PROJECT_SKU"
        elif [ $(FS_Is_Target_A_WASM_JS "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_WASM "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Chocolatey "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Homebrew "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Cargo "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_MSI "$_target") -eq 0 ]; then
                return 10 # not applicable
        else
                # copy main program
                # TIP: (1) usually is: usr/local/bin or usr/local/sbin
                #      (2) please avoid: bin/, usr/bin/, sbin/, and usr/sbin/
                ___dest="${_directory}/data/usr/local/bin"

                I18N_Copy "$_target" "$___dest"
                FS_Make_Directory "$___dest"
                FS_Copy_File "$_target" "$___dest"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi
        fi


        # NOTE: REQUIRED file
        _changelog_path="${_directory}/data/usr/local/share/doc/${PROJECT_SKU}/changelog.gz"
        if [ "$PROJECT_DEBIAN_IS_NATIVE" = "true" ]; then
                _changelog_path="${_directory}/data/usr/share/doc/${PROJECT_SKU}/changelog.gz"
        fi

        I18N_Create "$_changelog_path"
        DEB_Create_Changelog "$_changelog_path" "$_changelog" "$PROJECT_SKU"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # NOTE: REQUIRED file
        _copyright="${_directory}/data/usr/local/share/doc/${PROJECT_SKU}/copyright"
        if [ "$PROJECT_DEBIAN_IS_NATIVE" = "true" ]; then
                _copyright="${_directory}/data/usr/share/doc/${PROJECT_SKU}/copyright"
        fi

        I18N_Create "$_copyright"
        COPYRIGHT_Create \
                "$_copyright" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/licenses/deb-copyright" \
                "$PROJECT_SKU" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # NOTE: REQUIRED file
        _manual="${_directory}/data/usr/local/share/man/man1/${PROJECT_SKU}.1"
        if [ "$PROJECT_DEBIAN_IS_NATIVE" = "true" ]; then
                _manual="${_directory}/data/usr/share/man/man1/${PROJECT_SKU}.1"
        fi

        I18N_Create "$_manual"
        MANUAL_Create \
                "$_manual" \
                "$PROJECT_SKU" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # NOTE: REQUIRED file
        I18N_Create "${_directory}/control/md5sum"
        DEB_Create_Checksum "$_directory"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # NOTE: OPTIONAL (Comment to turn it off)
        I18N_Create "${_directory}/source.list"
        DEB_Create_Source_List \
                "$_directory" \
                "$PROJECT_GPG_ID" \
                "$PROJECT_STATIC_URL" \
                "$PROJECT_REPREPRO_CODENAME" \
                "$PROJECT_DEBIAN_DISTRIBUTION" \
                "$_gpg_keyring"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # WARNING: THIS REQUIRED FILE MUST BE THE LAST ONE
        I18N_Create "${_directory}/control/control"
        DEB_Create_Control \
                "$_directory" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}" \
                "$_package" \
                "$PROJECT_VERSION" \
                "$_target_arch" \
                "$_target_os" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_PITCH" \
                "$PROJECT_DEBIAN_PRIORITY" \
                "$PROJECT_DEBIAN_SECTION" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/docs/ABSTRACTS.txt"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # report status
        return 0
}

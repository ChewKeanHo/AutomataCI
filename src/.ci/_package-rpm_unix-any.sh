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

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




PACKAGE_Assemble_RPM_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate target before job
        case "$_target_arch" in
        avr)
                return 10 # not applicable
                ;;
        *)
                ;;
        esac

        _gpg_keyring="$PROJECT_SKU"
        if [ $(FS_Is_Target_A_Source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Docs "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Library "$_target") -eq 0 ]; then
                # copy main library
                # TIP: (1) usually is: usr/local/lib
                #      (2) please avoid: lib/, lib{TYPE}/ usr/lib/, and usr/lib{TYPE}/
                _filepath="${_directory}/BUILD/lib${PROJECT_SKU}.a"
                I18N_Copy "$_target" "$_filepath"
                FS_Make_Housing_Directory "$_filepath"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi

                FS_Copy_File "$_target" "$_filepath"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi


                # generate AutomataCI's required RPM spec instructions (INSTALL)
                __file="${_directory}/SPEC_INSTALL"
                I18N_Create "$__file"
                FS_Write_File "$__file" "\
install --directory %{buildroot}/usr/local/lib/${PROJECT_SKU}
install -m 0644 lib${PROJECT_SKU}.a %{buildroot}/usr/local/lib/${PROJECT_SKU}

install --directory %{buildroot}/usr/local/share/doc/lib${PROJECT_SKU}/
install -m 0644 copyright %{buildroot}/usr/local/share/doc/lib${PROJECT_SKU}/
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi


                # generate AutomataCI's required RPM spec instructions (FILES)
                __file="${_directory}/SPEC_FILES"
                I18N_Create "$__file"
                FS_Write_File "$__file" "\
/usr/local/lib/${PROJECT_SKU}/lib${PROJECT_SKU}.a
/usr/local/share/doc/lib${PROJECT_SKU}/copyright
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
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
                # TIP: (1) copy all files into "${__directory}/BUILD" directory.
                _filepath="${_directory}/BUILD/${PROJECT_SKU}"
                I18N_Copy "$_target" "$_filepath"
                FS_Make_Housing_Directory "$_filepath"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi

                FS_Copy_File "$_target" "$_filepath"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi


                # generate AutomataCI's required RPM spec instructions (INSTALL)
                __file="${_directory}/SPEC_INSTALL"
                I18N_Create "$__file"
                FS_Write_File "$__file" "\
install --directory %{buildroot}/usr/local/bin
install -m 0755 ${PROJECT_SKU} %{buildroot}/usr/local/bin

install --directory %{buildroot}/usr/local/share/doc/${PROJECT_SKU}/
install -m 0644 copyright %{buildroot}/usr/local/share/doc/${PROJECT_SKU}/

install --directory %{buildroot}/usr/local/share/man/man1/
install -m 0644 ${PROJECT_SKU}.1.gz %{buildroot}/usr/local/share/man/man1/
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi


                # generate AutomataCI's required RPM spec instructions (FILES)
                __file="${_directory}/SPEC_FILES"
                I18N_Create "$__file"
                FS_Write_File "$__file" "\
/usr/local/bin/${PROJECT_SKU}
/usr/local/share/doc/${PROJECT_SKU}/copyright
/usr/local/share/man/man1/${PROJECT_SKU}.1.gz
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi

                _package="$PROJECT_SKU"
        fi


        # NOTE: REQUIRED file
        I18N_Create "copyright.gz"
        COPYRIGHT_Create \
                "${_directory}/BUILD/copyright" \
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
        I18N_Create "MAN PAGES"
        MANUAL_Create \
                "${_directory}/BUILD/${PROJECT_SKU}.1" \
                "$PROJECT_SKU" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # NOTE: OPTIONAL (Comment to turn it off)
        I18N_Create "source.repo"
        RPM_Create_Source_Repo \
                "$PROJECT_SIMULATE_RELEASE_REPO" \
                "$_directory" \
                "$PROJECT_GPG_ID" \
                "$PROJECT_STATIC_URL" \
                "$PROJECT_NAME" \
                "$_gpg_keyring"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # WARNING: THIS REQUIRED FILE MUST BE THE LAST ONE
        I18N_Create "spec"
        RPM_Create_Spec \
                "$_directory" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}" \
                "$_package" \
                "$PROJECT_VERSION" \
                "$PROJECT_CADENCE" \
                "$PROJECT_PITCH" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_LICENSE" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/docs/ABSTRACTS.txt"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # report status
        return 0
}

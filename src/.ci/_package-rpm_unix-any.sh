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
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/archive/zip.sh"
. "${LIBS_AUTOMATACI}/services/compilers/rpm.sh"




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


        # execute
        ## determine base path
        ## TIP: (1) by design, usually is: usr/local/
        ##      (2) please avoid: usr/, usr/{TYPE}/, usr/bin/, & usr/lib{TYPE}/
        ##          whenever possible for avoiding conflicts with your OS native
        ##          system packages.
        _chroot="usr"
        if [ ! "$(STRINGS_To_Lowercase "$PROJECT_DEBIAN_IS_NATIVE")" = "true" ]; then
                _chroot="${_chroot}/local"
        fi

        _gpg_keyring="$PROJECT_SKU"
        if [ $(FS_Is_Target_A_Source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Docs "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Library "$_target") -eq 0 ]; then
                if [ $(FS_Is_Target_A_NPM "$_target") -eq 0 ]; then
                        return 10 # not applicable
                elif [ $(FS_Is_Target_A_TARGZ "$_target") -eq 0 ]; then
                        # unpack library
                        ___source="${PROJECT_SCOPE}/${PROJECT_SKU}"
                        ___dest="${_directory}/BUILD/${___source}"
                        ___target="${_chroot}/lib/${___source}"

                        I18N_Assemble "$_target" "$___dest"
                        FS_Make_Directory "$___dest"
                        TAR_Extract_GZ "$___dest" "$_target"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi

                        RPM_Register "$_directory" "$___source" "$___target" "true"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
                elif [ $(FS_Is_Target_A_TARXZ "$_target") -eq 0 ]; then
                        # unpack library
                        ___source="${PROJECT_SCOPE}/${PROJECT_SKU}"
                        ___dest="${_directory}/BUILD/${___source}"
                        ___target="${_chroot}/lib/${___source}"

                        I18N_Assemble "$_target" "$___dest"
                        FS_Make_Directory "$___dest"
                        TAR_Extract_XZ "$___dest" "$_target"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi

                        RPM_Register "$_directory" "$___source" "$___target" "true"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
                elif [ $(FS_Is_Target_A_ZIP "$_target") -eq 0 ]; then
                        # unpack library
                        ___source="${PROJECT_SCOPE}/${PROJECT_SKU}"
                        ___dest="${_directory}/BUILD/${___source}"
                        ___target="${_chroot}/lib/${___source}"

                        I18N_Assemble "$_target" "$___dest"
                        FS_Make_Directory "$___dest"
                        ZIP_Extract "$___dest" "$_target"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi

                        RPM_Register "$_directory" "$___source" "$___target" "true"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
                else
                        # copy library file
                        ___source="$(FS_Get_File "$_target")"
                        ___dest="${_directory}/BUILD/${___source}"
                        ___target="${_chroot}/lib/${___source}"

                        I18N_Assemble "$_target" "$___dest"
                        FS_Make_Housing_Directory "$___dest"
                        FS_Copy_File "$_target" "$___dest"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi

                        RPM_Register "$_directory" "$___source" "$___target"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
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
        elif [ $(FS_Is_Target_A_PDF "$_target") -eq 0 ]; then
                return 10 # not applicable
        else
                # copy main program
                ___source="$(FS_Get_File "$_target")"
                ___dest="${_directory}/BUILD/${___source}"
                ___target="${_chroot}/bin/${___source}"

                I18N_Assemble "$_target" "$___dest"
                FS_Make_Housing_Directory "$___dest"
                FS_Copy_File "$_target" "$___dest"
                if [ $? -ne 0 ]; then
                        I18N_Assemble_Failed
                        return 1
                fi

                RPM_Register "$_directory" "$___source" "$___target"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi

                _package="$PROJECT_SKU"
        fi


        # NOTE: REQUIRED file
        ___source="copyright"
        ___dest="${_directory}/BUILD/${___source}"
        ___target="${_chroot}/share/doc/${PROJECT_SCOPE}/${PROJECT_SKU}/${___source}"
        I18N_Create "$___source"
        COPYRIGHT_Create \
                "$___dest" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/licenses/deb-copyright" \
                "$PROJECT_SKU" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi

        RPM_Register "$_directory" "$___source" "$___target"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # NOTE: REQUIRED file
        ___source="${PROJECT_SCOPE}-${PROJECT_SKU}.1"
        ___dest="${_directory}/BUILD/${___source}"
        ___target="${_chroot}/share/man/man1/${___source}"
        I18N_Create "$___source"
        MANUAL_Create \
                "$___dest" \
                "$PROJECT_SKU" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi

        RPM_Register "$_directory" "$___source" "$___target"
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

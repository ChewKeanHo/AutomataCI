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


        # execute
        ## determine base path
        ## TIP: (1) by design, usually is: usr/local/
        ##      (2) please avoid: usr/, usr/{TYPE}/, usr/bin/, & usr/lib{TYPE}/
        ##          whenever possible for avoiding conflicts with your OS native
        ##          system packages.
        _chroot="${_directory}/data/usr"
        if [ ! "$(STRINGS_To_Lowercase "$PROJECT_DEB_IS_NATIVE")" = "true" ]; then
                _chroot="${_chroot}/local"
        fi

        _gpg_keyring="$PROJECT_SKU"
        _package="$PROJECT_SKU"
        if [ $(FS_Is_Target_A_Source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Docs "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Library "$_target") -eq 0 ]; then
                __dest="${_chroot}/lib/${PROJECT_SCOPE}/${PROJECT_SKU}"

                if [ $(FS_Is_Target_A_NPM "$_target") -eq 0 ]; then
                        return 10 # not applicable
                elif [ $(FS_Is_Target_A_TARGZ "$_target") -eq 0 ]; then
                        # unpack library
                        I18N_Assemble "$_target" "$__dest"
                        FS_Make_Directory "$__dest"
                        TAR_Extract_GZ "$__dest" "$_target"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
                elif [ $(FS_Is_Target_A_TARXZ "$_target") -eq 0 ]; then
                        # unpack library
                        I18N_Assemble "$_target" "$__dest"
                        FS_Make_Directory "$__dest"
                        TAR_Extract_XZ "$__dest" "$_target"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
                elif [ $(FS_Is_Target_A_ZIP "$_target") -eq 0 ]; then
                        # unpack library
                        I18N_Assemble "$_target" "$__dest"
                        FS_Make_Directory "$__dest"
                        ZIP_Extract "$__dest" "$_target"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
                else
                        # copy library file
                        __dest="${__dest}/$(FS_Get_File "$_target")"
                        I18N_Assemble "$_target" "$__dest"
                        FS_Make_Directory "$__dest"
                        FS_Copy_File "$_target" "$__dest"
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
                __dest="${_chroot}/bin/${PROJECT_SKU}"

                I18N_Assemble "$_target" "$__dest"
                FS_Make_Housing_Directory "$__dest"
                FS_Copy_File "$_target" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Assemble_Failed
                        return 1
                fi
        fi


        # NOTE: REQUIRED file
        __dest="${_chroot}/share/doc/${PROJECT_SCOPE}/${PROJECT_SKU}/changelog.gz"
        I18N_Create "$__dest"
        DEB_Create_Changelog "$__dest" "$_changelog" "$PROJECT_SKU"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # NOTE: REQUIRED file
        __dest="${_chroot}/share/doc/${PROJECT_SCOPE}/${PROJECT_SKU}/copyright"
        I18N_Create "$__dest"
        COPYRIGHT_Create \
                "$__dest" \
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
        __dest="${_chroot}/share/man/man1/${PROJECT_SCOPE}-${PROJECT_SKU}.1"
        I18N_Create "$__dest"
        MANUAL_Create \
                "$__dest" \
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
        __url="$PROJECT_STATIC_URL"
        if [ $(STRINGS_Is_Empty "$PROJECT_DEB_URL") -ne 0 ]; then
                __url="$PROJECT_DEB_URL"
        fi

        DEB_Create_Source_List \
                "$_directory" \
                "$PROJECT_GPG_ID" \
                "$__url" \
                "$PROJECT_DEB_COMPONENT" \
                "$PROJECT_DEB_DISTRIBUTION" \
                "$_gpg_keyring"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # WARNING: THIS REQUIRED FILE MUST BE THE LAST ONE
        __arch="$_target_arch"
        if [ "$__arch" = "any" ]; then
                __arch="all"
        fi

        __os="$_target_os"
        if [ "$__os" = "any" ]; then
                __os="all"
        fi

        I18N_Create "${_directory}/control/control"
        DEB_Create_Control \
                "$_directory" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}" \
                "$_package" \
                "$PROJECT_VERSION" \
                "$__arch" \
                "$__os" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_PITCH" \
                "$PROJECT_DEB_PRIORITY" \
                "$PROJECT_DEB_SECTION" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/docs/ABSTRACTS.txt"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # report status
        return 0
}

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
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/rust.sh"




PACKAGE_Assemble_CARGO_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate project
        if [ $(FS_Is_Target_A_Cargo "$_target") -ne 0 ]; then
                return 10
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_RUST") -eq 0 ]; then
                return 10
        fi


        # assemble the cargo package
        ___source="${PROJECT_PATH_ROOT}/${PROJECT_RUST}/"
        I18N_Assemble "$___source" "$_directory"
        FS_Copy_All "$___source" "$_directory"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/${PROJECT_CARGO_README}"
        ___dest="${_directory}/README.md"
        I18N_Assemble "$___source" "$___dest"
        FS_Copy_File "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___dest="${_directory}/Cargo.toml"
        I18N_Create "$___dest"
        FS_Remove_Silently "${_directory}/Cargo.lock"
        FS_Remove_Silently "${_directory}/.ci"
        RUST_Create_CARGO_TOML \
                "$___dest" \
                "${PROJECT_PATH_ROOT}/${PROJECT_RUST}/Cargo.toml" \
                "$PROJECT_SKU" \
                "$PROJECT_VERSION" \
                "$PROJECT_PITCH" \
                "$PROJECT_RUST_EDITION" \
                "$PROJECT_LICENSE" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_SOURCE_URL" \
                "README.md" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # report status
        return 0
}

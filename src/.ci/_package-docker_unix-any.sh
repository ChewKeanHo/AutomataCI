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




PACKAGE_Assemble_DOCKER_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate project
        if [ $(FS_Is_Target_A_Source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Docs "$_target") -eq 0 ]; then
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
        elif [ $(FS_Is_Target_A_Cargo "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_MSI "$_target") -eq 0 ]; then
                return 10 # not applicable
        fi

        case "$_target_os" in
        linux|windows)
                ;;
        *)
                return 10
                ;;
        esac


        # assemble the package
        FS_Copy_File "$_target" "${_directory}/${PROJECT_SKU}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Touch_File "${_directory}/.blank"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # generate the Dockerfile
        FS_Write_File "${_directory}/Dockerfile" "\
# Defining baseline image
"
        if [ "$_target_os" = "windows" ]; then
                FS_Append_File "${_directory}/Dockerfile" "\
FROM --platform=${_target_os}/${_target_arch} mcr.microsoft.com/windows/nanoserver:ltsc2022
"
        else
                FS_Append_File "${_directory}/Dockerfile" "\
FROM --platform=${_target_os}/${_target_arch} busybox:latest
"
        fi

        FS_Append_File "${_directory}/Dockerfile" "\
LABEL org.opencontainers.image.title=\"${PROJECT_NAME}\"
LABEL org.opencontainers.image.description=\"${PROJECT_PITCH}\"
LABEL org.opencontainers.image.authors=\"${PROJECT_CONTACT_NAME} <${PROJECT_CONTACT_EMAIL}>\"
LABEL org.opencontainers.image.version=\"${PROJECT_VERSION}\"
LABEL org.opencontainers.image.revision=\"${PROJECT_CADENCE}\"
LABEL org.opencontainers.image.licenses=\"${PROJECT_LICENSE}\"
"

        if [ $(STRINGS_Is_Empty "$PROJECT_CONTACT_WEBSITE") -ne 0 ]; then
                FS_Append_File "${_directory}/Dockerfile" "\
LABEL org.opencontainers.image.url=\"${PROJECT_CONTACT_WEBSITE}\"
"
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_SOURCE_URL") -ne 0 ]; then
                FS_Append_File "${_directory}/Dockerfile" "\
LABEL org.opencontainers.image.source=\"${PROJECT_SOURCE_URL}\"
"
        fi

        FS_Append_File "${_directory}/Dockerfile" "\
# Defining environment variables
ENV ARCH ${_target_arch}
ENV OS ${_target_os}
ENV PORT 80

# Assemble the file structure
COPY .blank /tmp/.tmpfile
ADD ${PROJECT_SKU} /app/bin/${PROJECT_SKU}

# Set network port exposures
EXPOSE 80

# Set entry point
ENTRYPOINT [\"/app/bin/${PROJECT_SKU}\"]
"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}

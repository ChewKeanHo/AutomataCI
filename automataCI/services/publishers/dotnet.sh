#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/net/http.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/archive/zip.sh"




DOTNET_Add() {
        ___order="$1"
        ___version="$2"
        ___destination="$3"
        ___extractions="$4"


        # validate input
        if [ $(STRINGS_Is_Empty "$___order") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$___version") -eq 0 ]; then
                ___version="latest"
        fi
        ___version="$(STRINGS_To_Lowercase "${___version}")"


        # execute
        ___pkg="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_NUPKG}"
        ___pkg="${___pkg}/${___order}_${___version}"
        if [ "$___version" = "latest" ]; then
                FS_Remove_Silently "$___pkg"
        fi

        ## begin sourcing nupkg
        FS_Is_File "${___pkg}/nupkg.zip"
        if [ $? -ne 0 ]; then
                ___order="https://www.nuget.org/api/v2/package/${___order}"
                if [ ! "$___version" = "latest" ]; then
                        ___order="${___order}/${___version}"
                fi

                FS_Make_Directory "$___pkg"
                HTTP_Download "GET" "$___order" "${___pkg}/nupkg.zip"
                if [ $? -ne 0 ]; then
                        FS_Remove_Silently "$___pkg"
                        return 1
                fi

                FS_Is_File "${___pkg}/nupkg.zip"
                if [ $? -ne 0 ]; then
                        FS_Remove_Silently "$___pkg"
                        return 1
                fi

                ZIP_Extract "$___pkg" "${___pkg}/nupkg.zip"
                if [ $? -ne 0 ]; then
                        FS_Remove_Silently "$___pkg"
                        return 1
                fi
        fi

        ## begin extraction
        if [ $(STRINGS_Is_Empty "$___extractions") -eq 0 ]; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$___destination") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$___destination"
        if [ $? -eq 0 ]; then
                return 1
        fi
        FS_Make_Directory "$___destination"

        while [ $(STRINGS_Is_Empty "$___extractions") -ne 0 ]; do
                ___target="${___extractions%%|*}"
                ___src="${___pkg}/${___target}"
                ___dest="${___destination}/${___target##*/}"

                FS_Is_File "$___src"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                FS_Remove_Silently "$___dest"
                FS_Copy_File "$___src" "$___dest"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                ### update for next extraction
                ___extractions="${___extractions#*|}"
                if [ "$___target" = "$___extractions" ]; then
                        break
                fi
        done


        # report status
        return 0
}




DOTNET_Activate_Environment() {
        # validate input
        DOTNET_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        DOTNET_Is_Activated
        if [ $? -eq 0 ]; then
                return 1
        fi


        # execute
        DOTNET_ROOT="$(DOTNET_Get_Path_Root)"
        DOTNET_CLI_TELEMETRY_OPTOUT=1
        alias dotnet="$(DOTNET_Get_Path_Root)/dotnet"


        # report status
        DOTNET_Is_Activated
        if [ $? -ne 0 ]; then
                return 1
        fi

        return 0
}




DOTNET_Get_Path_Bin() {
        # execute
        printf -- "%b" "${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/dotnet-engine/bin"


        # report status
        return 0
}




DOTNET_Get_Path_Root() {
        # execute
        printf -- "%b" "${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_DOTNET_ENGINE}"


        # report status
        return 0
}




DOTNET_Install() {
        #__order="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        DOTNET_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        DOTNET_Activate_Environment
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        dotnet tool install --tool-path "$(DOTNET::get_path_bin)" "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DOTNET_Is_Activated() {
        # execute
        if [ $(STRINGS_Is_Empty "$DOTNET_ROOT") -eq 0 ]; then
                return 1
        fi

        "${DOTNET_ROOT}/dotnet" help &> /dev/null
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DOTNET_Is_Available() {
        # execute
        FS_Is_File "$(DOTNET_Get_Path_Root)/dotnet"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




DOTNET_Setup() {
        # validate input
        DOTNET_Is_Available
        if [ $? -eq 0 ]; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_DOTNET_CHANNEL") -eq 0 ]; then
                return 1
        fi


        # execute
        "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/publishers/dotnet-install.sh" \
                --channel "$PROJECT_DOTNET_CHANNEL" \
                --install-dir "$(DOTNET_Get_Path_Root)"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}

#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
FS_Append_File() {
        #___target="$1"
        #___content="$2"


        # validate target
        if [ ! -z "$1" -a -z "$2" ] || [ -z "$1" ]; then
                return 1
        fi


        # perform file write
        printf -- "%b" "$2" >> "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




FS_Copy_All() {
        #___source="$1"
        #___destination="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        cp -r "${1}"* "${2}/."
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




FS_Copy_File() {
        #___source="$1"
        #___destination="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Target_Exist "$2"
        if [ $? -eq 0 ]; then
                return 1
        fi


        # execute
        cp "$1" "$2"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




FS_Extension_Remove() {
        printf -- "%s" "$(FS_Extension_Replace "$1" "$2" "")"
        return $?
}




FS_Extension_Replace() {
        #___path="$1"
        #___extension="$2"
        #___candidate="$3"


        # validate input
        if [ -z "$1" ]; then
                printf -- ""
                return 0
        fi


        # execute
        ## prepare working parameters
        ___target="${1##*/}"

        if [ "$2" = "*" ]; then
                ## trim all extensions to the first period
                ___target="${___target%%.*}"

                ## restore directory pathing when available
                if [ ! -z "${1%/*}" ] && [ ! "${1%/*}" = "$1" ]; then
                        ___target="${1%/*}/${___target}"
                fi
        elif [ ! -z "$2" ]; then
                ## trim off existing extension
                if [ "$(printf -- "%.1s" "$2")" = "." ]; then
                        ___extension="${2#*.}"
                else
                        ___extension="$2"
                fi
                ___target="${___target%.${___extension}*}"

                ## append new extension when available
                if [ ! "${___target}" = "${1##*/}" ]; then
                        if [ ! -z "$3" ]; then
                                if [ "$(printf -- "%.1s" "$3")" = "." ]; then
                                        ___target="${___target}.${3#*.}"
                                else
                                        ___target="${___target}.${3}"
                                fi
                        fi
                fi

                ## restore directory pathing when available
                if [ ! -z "${1%/*}" ] && [ ! "${1%/*}" = "$1" ]; then
                        ___target="${1%/*}/${___target}"
                fi
        else
                ## do nothing
                ___target="$1"
        fi


        # report status
        printf -- "%s" "$___target"
        return 0
}




FS_Get_Directory() {
        #___target="$1"


        # validate input
        if [ -z "$1" ]; then
                printf -- ""
                return 1
        fi


        # execute
        printf -- "%b" "${1%/*}"


        # report status
        return 0
}




FS_Get_File() {
        #___target="$1"


        # validate input
        if [ -z "$1" ]; then
                printf -- ""
                return 1
        fi


        # execute
        printf -- "%b" "${1##*/}"


        # report status
        return 0
}




FS_Get_MIME() {
        #___target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi


        # execute
        ___output="$(file --mime-type "$1")"
        if [ $? -eq 0 ]; then
                printf -- "%b" "${___output##* }"
                return 0
        fi


        # report status
        printf -- ""
        return 1
}




FS_Get_Path_Relative() {
        #___target="$1"
        #___base="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                printf -- ""
                return 1
        fi


        # execute
        printf -- "%b" "${1#*${2}/}"


        # report status
        return 0
}




FS_Is_Directory() {
        #___target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi


        # execute
        if [ -d "$1" ]; then
                return 0
        fi


        # report status
        return 1
}




FS_Is_Directory_Empty() {
        #___target="$1"


        # validate input
        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 0
        fi


        # execute
        for ___item in "$1"/*; do
                if [ -e "$___item" ]; then
                        return 1
                fi
        done


        # report status
        return 0
}




FS_Is_File() {
        #___target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi


        # execute
        FS_Is_Directory "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi

        if [ -f "$1" ]; then
                return 0
        fi


        # report status
        return 1
}




FS_Is_Target_A_C() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        if [ $(FS_Is_Target_A_Cargo "$1") -eq 0 ]; then
                return 1
        fi

        if [ $(FS_Is_Target_A_Chocolatey "$1") -eq 0 ]; then
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*-C}" != "$___file_subject" ] ||
                [ "${___file_subject#*-c}" != "$___file_subject" ] ||
                [ "${___file_subject#*.c}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_Cargo() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*-cargo}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_Chocolatey() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*-chocolatey}" != "$___file_subject" ] ||
                [ "${___file_subject#*-choco}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_Citation_CFF() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*.cff}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_Docs() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*-doc}" != "$___file_subject" ] ||
                [ "${___file_subject#*-docs}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_Homebrew() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*-homebrew}" != "$___file_subject" ] ||
                [ "${___file_subject#*-brew}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_Library() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#lib*}" != "$___file_subject" ] ||
                [ "${___file_subject#*.a}" != "$___file_subject" ] ||
                [ "${___file_subject#*.dll}" != "$___file_subject" ] ||
                [ "${___file_subject#*-lib}" != "$___file_subject" ] ||
                [ "${___file_subject#*-libs}" != "$___file_subject" ] ||
                [ "${___file_subject#*-library}" != "$___file_subject" ] ||
                [ "${___file_subject#*-libraries}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_MSI() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*-msi}" != "$___file_subject" ] ||
                [ "${___file_subject#*.msi}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_NPM() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*_js-js.tgz}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_Nupkg() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*.nupkg}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_PDF() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*.pdf}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_PYPI() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*-pypi}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_Source() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*-src}" != "$___file_subject" ] ||
                [ "${___file_subject#*-source}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_TARGZ() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*.tar.gz}" != "$___file_subject" ] ||
                [ "${___file_subject#*.tgz}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_TARXZ() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*.tar.xz}" != "$___file_subject" ] ||
                [ "${___file_subject#*.txz}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_WASM() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*-wasm}" != "$___file_subject" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_A_WASM_JS() {
        #___subject="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        if [ $(FS_Is_Target_A_WASM "$1") -ne 0 ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*.js}" == "$___file_subject" ]; then
                printf -- "1"
                return 1
        fi


        # report status
        printf -- "0"
        return 0
}




FS_Is_Target_A_ZIP() {
        #___target="$1"


        # execute
        if [ "$1" = "" ]; then
                printf -- "1"
                return 1
        fi

        ___file_subject="$(FS_Get_File "$1")"
        if [ "${___file_subject#*.zip}" != "${___file_subject}" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS_Is_Target_Exist() {
        #___target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi


        # perform checking
        if [ -e "$1" ]; then
                return 0
        fi


        # report status
        return 1
}




FS_List_All() {
        #___target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ls -la "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi
        return 1
}




FS_Make_Directory() {
        #___target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi

        FS_Is_Target_Exist "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi


        # execute
        mkdir -p "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




FS_Make_Housing_Directory() {
        #___target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # perform create
        FS_Make_Directory "${1%/*}"


        # report status
        return $?
}




FS_Move() {
        #___source="$1"
        #___destination="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi

        FS_Is_Target_Exist "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        mv "$1" "$2"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




FS_Remake_Directory() {
        #___target="$1"


        # execute
        FS_Remove_Silently "$1"
        FS_Make_Directory "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




FS_Remove() {
        #___target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi


        # execute
        rm -rf "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




FS_Remove_Silently() {
        #___target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 0
        fi


        # execute
        rm -rf "$1" &> /dev/null


        # report status
        return 0
}




FS_Rename() {
        #___source="$1"
        #___target="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi

        FS_Is_Target_Exist "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Target_Exist "$2"
        if [ $? -eq 0 ]; then
                return 1
        fi


        # execute
        FS_Move "$1" "$2"
        return $?
}




FS_Touch_File() {
        #___target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        touch "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




FS_Write_File() {
        #___target="$1"
        #___content="$2"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi


        # perform file write
        printf -- "%b" "$2" > "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}

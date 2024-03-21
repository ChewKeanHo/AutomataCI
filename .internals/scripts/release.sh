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




# determine PROJECT_PATH_PWD
export PROJECT_PATH_PWD="$PWD"
export PROJECT_PATH_AUTOMATA="automataCI"




# determine PROJECT_PATH_ROOT
if [ -f "./ci.sh" ]; then
        PROJECT_PATH_ROOT="${PWD%/*}/"
elif [ -f "./${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
        # current directory is the root directory.
        PROJECT_PATH_ROOT="$PWD"
else
        __pathing="$PROJECT_PATH_PWD"
        __previous=""
        while [ "$__pathing" != "" ]; do
                PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT}${__pathing%%/*}/"
                __pathing="${__pathing#*/}"
                if [ -f "${PROJECT_PATH_ROOT}${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
                        break
                fi

                # stop the scan if the previous pathing is the same as current
                if [ "$__previous" = "$__pathing" ]; then
                        1>&2 printf "[ ERROR ] [ ERROR ] Missing root directory.\n"
                        return 1
                fi
                __previous="$__pathing"
        done
        unset __pathing __previous
        export PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT%/*}"

        if [ ! -f "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
                1>&2 printf "[ ERROR ] [ ERROR ] Missing root directory.\n"
                exit 1
        fi
fi

export LIBS_AUTOMATACI="${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}"




# import fundamental libraries
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




# determine host system parameters
export PROJECT_OS="$(OS_Get)"
if [ "$(STRINGS_Is_Empty "$PROJECT_OS")" -eq 0 ]; then
        I18N_Unsupported_OS
        return 1
fi

export PROJECT_ARCH="$(OS_Get_Arch)"
if [ "$(STRINGS_Is_Empty "$PROJECT_ARCH")" -eq 0 ]; then
        I18N_Unsupported_ARCH
        return 1
fi




# parse repo CI configurations
if [ ! -f "${PROJECT_PATH_ROOT}/CONFIG.toml" ]; then
        I18N_Missing "CONFIG.toml"
        return 1
fi


__old_IFS="$IFS"
while IFS= read -r __line || [ -n "$__line" ]; do
        __line="${__line%%#*}"
        if [ "$(STRINGS_Is_Empty "$__line")" -eq 0 ]; then
                continue
        fi

        key="${__line%%=*}"
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        key="${key%\"}"
        key="${key#\"}"
        key="${key%\'}"
        key="${key#\'}"

        value="${__line##*=}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"

        export "$key"="$value"
done < "${PROJECT_PATH_ROOT}/CONFIG.toml"
IFS="$__old_IFS" && unset __old_IFS




# parse repo CI secret configurations
if [ -f "${PROJECT_PATH_ROOT}/SECRETS.toml" ]; then
        __old_IFS="$IFS"
        while IFS= read -r __line || [ -n "$__line" ]; do
                __line="${__line%%#*}"
                if [ "$(STRINGS_Is_Empty "$__line")" -eq 0 ]; then
                        continue
                fi

                key="${__line%%=*}"
                key="${key#"${key%%[![:space:]]*}"}"
                key="${key%"${key##*[![:space:]]}"}"
                key="${key%\"}"
                key="${key#\"}"
                key="${key%\'}"
                key="${key#\'}"

                value="${__line##*=}"
                value="${value#"${value%%[![:space:]]*}"}"
                value="${value%"${value##*[![:space:]]}"}"
                value="${value%\"}"
                value="${value#\"}"
                value="${value%\'}"
                value="${value#\'}"

                export "$key"="$value"
        done < "${PROJECT_PATH_ROOT}/SECRETS.toml"
        IFS="$__old_IFS" && unset __old_IFS
fi




# determine language
export AUTOMATACI_LANG="${AUTOMATACI_LANG:-$(OS_Get_Lang)}"
if [ "$(STRINGS_Is_Empty "$AUTOMATACI_LANG")" -eq 0 ]; then
        export AUTOMATACI_LANG="en" # fall back to english
fi




# update environment variable
OS_Sync
cd "$PROJECT_PATH_ROOT"




# clean up harsh data
FS_Remove_Silently "srcANGULAR/node_modules"
FS_Remove_Silently "srcANGULAR/.angular"




# execute command
___directory="pkgAUTOMATACI"
FS_Remake_Directory "$___directory"
sync

old_IFS="$IFS"
while IFS="" read -r __line || [ -n "$__line" ]; do
        if [ $(STRINGS_Is_Empty "$__line") -eq 0 ]; then
                continue
        fi


        # build the file
        if [ "$__line" = "automataCI" ]; then
                tar czvf "${___directory}/AutomataCI-${PROJECT_VERSION}-core.tar.gz" \
                        -C "$PROJECT_PATH_ROOT" "$__line" \
                        -C "$PROJECT_PATH_ROOT" "CONFIG.toml" \
                        -C "$PROJECT_PATH_ROOT" ".gitignore"
        else
                tar czvf "${___directory}/AutomataCI-${PROJECT_VERSION}-${__line}.tar.gz" \
                        -C "$PROJECT_PATH_ROOT" "$__line"
        fi
done <<EOF
automataCI
src
srcC
srcNIM
srcRUST
srcGO
srcPYTHON
srcANGULAR
EOF




# copy official documents
__old_IFS="$IFS"
find ".internals/docs/" -name '*.pdf' -print0 \
        | while IFS="" read -r ___file_src || [ -n "$___file_src" ]; do
        if [ $(STRINGS_Is_Empty "$___file_src") -eq 0 ]; then
                continue
        fi

        ___file="${___file_src##*/}"
        ___file="$(FS_Extension_Remove "$___file" "*")"
        1>&2 printf -- "%b --> %b \n" "$___file_src" "$___file"
        cp "$___file_src" \
                "${___directory}/AutomataCI-${PROJECT_VERSION}-User-Guide_${___file##*_}.pdf"
done
IFS="$__old_IFS" && unset __old_IFS




# report status
exit 0

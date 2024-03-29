#!/bin/bash
# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/ai/google.sh"




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




# conversion
interpret_lang() {
        case "$1" in
        de)
                printf -- "%b" "German"
                ;;
        en)
                printf -- "%b" "English"
                ;;
        es)
                printf -- "%b" "Spanish"
                ;;
        fr)
                printf -- "%b" "French"
                ;;
        jp)
                printf -- "%b" "Japanese"
                ;;
        ko)
                printf -- "%b" "Korean"
                ;;
        mn)
                printf -- "%b" "Mongolian"
                ;;
        nb)
                printf -- "%b" "Norwegian - Bokmaal"
                ;;
        nl)
                printf -- "%b" "Dutch"
                ;;
        nn)
                printf -- "%b" "Norwegian - Nynorsk"
                ;;
        ru)
                printf -- "%b" "Russian"
                ;;
        sv)
                printf -- "%b" "Swedish"
                ;;
        uk)
                printf -- "%b" "Ukrainian"
                ;;
        zh-hans)
                printf -- "%b" "Simplified Chinese"
                ;;
        zh-hant)
                printf -- "%b" "Traditional Chinese"
                ;;
        *)
                printf -- ""
                return 1
                ;;
        esac


        # report status
        return 0
}




# execute command
___filter="candidates[0].content.parts[0].text"


# interpret origin language
___lang_from="$(interpret_lang "$1")"
I18N_Check "AI<<<: ${___lang_from}"
if [ $(STRINGS_Is_Empty "$___lang_from") -eq 0 ]; then
        I18N_Check_Failed
        exit 1
fi


# interpret destination language
___lang_to="$(interpret_lang "$2")"
I18N_Check "AI>>>: ${___lang_to}"
if [ $(STRINGS_Is_Empty "$___lang_to") -eq 0 ]; then
        I18N_Check_Failed
        exit 1
fi


# construct translation query statement
___query="\
Translate the following as it is without explaination from ${___lang_from} to \
${___lang_to}:

${3}

"
I18N_Check "...?\n${___query}"


___response="$(GOOGLEAI_Gemini_Query_Text_To_Text "$___query")"
if [ $? -ne 0 ]; then
        exit 1
fi


# parse json if available
if [ $(STRINGS_Is_Empty "$___response") -ne 0 ]; then
        OS_Is_Command_Available "jq"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$___response" | jq --raw-output ."${___filter}"
        fi
fi
I18N_Newline




# report status
I18N_Run_Successful
exit 0

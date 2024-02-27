# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
I18N_Status_Print() {
        #___mode="$1"
        #___message="$2"


        # execute
        ___tag="$(I18N_Status_Tag_Get_Type "$1")"
        ___color=""
        case "$1" in
        error)
                ___color="31"
                ;;
        warning)
                ___color="33"
                ;;
        info)
                ___color="36"
                ;;
        note)
                ___color="35"
                ;;
        success)
                ___color="32"
                ;;
        ok)
                ___color="36"
                ;;
        done)
                ___color="36"
                ;;
        *)
                # do nothing
                ;;
        esac

        if [ ! -z "$COLORTERM" ] || [ "$TERM" = "xterm-256color" ]; then
                # terminal supports color mode
                if [ ! -z "$___color" ]; then
                        1>&2 printf -- "%b" \
                                "\033[1;${___color}m${___tag}\033[0;${___color}m${2}\033[0m"
                else
                        1>&2 printf -- "%b" "${___tag}${2}"
                fi
        else
                1>&2 printf -- "%b" "${___tag}${2}"
        fi

        unset ___color ___tag
}




I18N_Status_Tag_Create() {
        #___content="$1"
        #___spacing="$2"


        # validate input
        if [ "$(STRINGS_Is_Empty "$1")" -eq 0 ]; then
                printf -- ""
                return 0
        fi


        # execute
        printf -- "%b" "⦗$1⦘$2"
        return 0
}




I18N_Status_Tag_Get_Type() {
        #___mode="$1"


        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                printf -- "%b" "$(I18N_Status_Tag_Get_Type_EN "$1")"
                ;;
        esac
}




I18N_Status_Tag_Get_Type_EN() {
        #___mode="$1"


        # execute (REMEMBER: make sure the text and spacing are having the same length)
        case "$1" in
        error)
                printf -- "%b" "$(I18N_Status_Tag_Create " ERROR " "   ")"
                ;;
        warning)
                printf -- "%b" "$(I18N_Status_Tag_Create " WARNING " " ")"
                ;;
        info)
                printf -- "%b" "$(I18N_Status_Tag_Create " INFO " "    ")"
                ;;
        note)
                printf -- "%b" "$(I18N_Status_Tag_Create " NOTE " "    ")"
                ;;
        success)
                printf -- "%b" "$(I18N_Status_Tag_Create " SUCCESS " " ")"
                ;;
        ok)
                printf -- "%b" "$(I18N_Status_Tag_Create " OK " "      ")"
                ;;
        done)
                printf -- "%b" "$(I18N_Status_Tag_Create " DONE " "    ")"
                ;;
        *)
                printf -- ""
                ;;
        esac
}

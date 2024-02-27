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
. "${LIBS_AUTOMATACI}/services/i18n/__printer.sh"
. "${LIBS_AUTOMATACI}/services/i18n/__param.sh"




I18N_Sign() {
        ___subject="$1"
        ___signer="$2"


        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                ___subject="$(I18N_Param_Process "${___subject}")"

                if [ $(STRINGS_Is_Empty "${___signer}") -ne 0 ]; then
                        I18N_Status_Print info "'${___signer}' signing '${___subject}'...\n"
                else
                        I18N_Status_Print info "signing '${___subject}'...\n"
                fi
                ;;
        esac


        # report status
        return 0
}

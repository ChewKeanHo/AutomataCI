# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/i18n/printer.sh"

. "${LIBS_AUTOMATACI}/services/i18n/_status-file-archive.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_status-file-check.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_status-file-create.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_status-file-export.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_status-file-update.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_status-file-validate.sh"




I18N_Status_Print_File_Assemble() {
        ___subject="$1"
        ___target="$2"


        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                ___subject="$(I18N_Status_Param_Process "${___subject}")"
                ___target="$(I18N_Status_Param_Process "${___target}")"
                I18N_Status_Print info "assembling file: ${___subject} as ${___target}\n"
                ;;
        esac


        # report status
        return 0
}




I18N_Status_Print_File_Detected() {
        ___subject="$1"


        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                ___subject="$(I18N_Status_Param_Process "${___subject}")"
                I18N_Status_Print info "detected file: ${___subject}\n"
                ;;
        esac


        # report status
        return 0
}




I18N_Status_Print_File_Incompatible_Skipped() {
        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                I18N_Status_Print warning "incompatible file. Skipping...\n"
                ;;
        esac


        # report status
        return 0
}




I18N_Status_Print_File_Injected() {
        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                I18N_Status_Print warning "manual injection detected.\n"
                ;;
        esac


        # report status
        return 0
}




I18N_Status_Print_File_Bad_Stat_Skipped() {
        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                I18N_Status_Print warning "failed to parse file. Skipping...\n"
                ;;
        esac


        # report status
        return 0
}




I18N_Status_Print_File_Write_Failed() {
        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                I18N_Status_Print error "write failed.\n\n"
                ;;
        esac


        # report status
        return 0
}

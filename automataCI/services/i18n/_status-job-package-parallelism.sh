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




I18N_Status_Print_Package_Parallelism_Register() {
        ___subject="$1"


        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                ___subject="$(I18N_Status_Param_Process "${___subject}")"
                I18N_Status_Print info "registering for packaging in parallel: ${___subject}\n"
                ;;
        esac


        # report status
        return 0
}




I18N_Status_Print_Package_Parallelism_Logdump() {
        ___subject="$1"


        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                ___subject="$(I18N_Status_Param_Process "${___subject}")"
                I18N_Status_Print info "log report from ${___subject}\n"
                ;;
        esac


        # report status
        return 0
}




I18N_Status_Print_Package_Parallelism_Run() {
        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                I18N_Status_Print info "executing parallel run...\n"
                ;;
        esac


        # report status
        return 0
}




I18N_Status_Print_Package_Parallelism_Run_Skipped() {
        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                I18N_Status_Print warning "no instruction found. Skipping...\n"
                ;;
        esac


        # report status
        return 0
}




I18N_Status_Print_Package_Parallelism_Run_Failed() {
        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                I18N_Status_Print error "exec failed.\n\n"
                ;;
        esac


        # report status
        return 0
}

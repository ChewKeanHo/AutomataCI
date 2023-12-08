#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/compilers/msi.sh"

. "${LIBS_AUTOMATACI}/services/i18n/printer.sh"
. "${LIBS_AUTOMATACI}/services/i18n/status-job-package.sh"
. "${LIBS_AUTOMATACI}/services/i18n/status-run.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from ci.cmd instead!\n"
        return 1
fi




SUBROUTINE_Package_MSI() {
        # parse input
        __line="$1"

        __target="${__line%%|*}"
        __line="${__line#*|}"

        __dest="${__line%%|*}"
        __line="${__line#*|}"

        __log="${__line%%|*}"

        __subject="${__log##*/}"
        __subject="${__subject%.*}"

        __arch="${__subject##*windows-}"
        __arch="${__arch%%_*}"


        # execute
        I18N_Status_Print_Package_Exec "${__subject}"
        MSI_Compile "$__target" "$__arch" &> "$__log"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Package_Exec_Failed "${__subject}"
                return 1
        fi

        __target="$(FS_Extension_Replace "$__target" ".wxs" ".msi")"
        I18N_Status_Print_Package_Export "$__subject"
        if [ ! -f "$__target" ]; then
                I18N_Status_Print_Package_Export_Failed_Missing "$__subject"
                return 1
        fi

        FS::copy_file "$__target" "${__dest}/${__target##*/}" &> "$__log"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Package_Export_Failed "$__subject"
                return 1
        fi


        # report status
        return 0
}




PACKAGE_Run_MSI() {
        #__line="$1"


        # parse input
        __line="$1"

        _dest="${__line%%|*}"
        __line="${__line#*|}"

        _target="${__line%%|*}"
        __line="${__line#*|}"

        _target_filename="${__line%%|*}"
        __line="${__line#*|}"

        _target_os="${__line%%|*}"
        __line="${__line#*|}"

        _target_arch="${__line%%|*}"
        __line="${__line#*|}"

        _target_arch="${__line##*|}"
        __line="${__line%|*}"


        # validate input
        I18N_Status_Print_Check_Availability "MSI"
        MSI_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Check_Availability_Failed "MSI"
                return 0
        fi


        # prepare workspace and required values
        I18N_Status_Print_Package_Create "MSI"
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/msi_${_src}"
        I18N_Status_Print_Package_Workspace_Remake "$_src"
        FS::remake_directory "$_src"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Package_Remake_Failed
                return 1
        fi

        __control_directory="${_src}/.automataCI"
        I18N_Status_Print_Package_Workspace_Remake_Control "$__control_directory"
        FS::remake_directory "$__control_directory"
        if [ ! -d "$__control_directory" ]; then
                I18N_Status_Print_Package_Remake_Failed
                return 1
        fi

        __parallel_control="${__control_directory}/control-parallel.txt"
        FS::remove_silently "$__parallel_control"


        # copy all complimentary files to the workspace
        I18N_Status_Print_Package_Assembler_Check "PACKAGE-Assemble-MSI-Content"
        if [ -z "$(type -t PACKAGE_Assemble_MSI_Content)" ]; then
                I18N_Status_Print_Package_Check_Failed
                return 1
        fi

        I18N_Status_Print_Package_Assembler_Exec
        PACKAGE_Assemble_MSI_Content \
                "$_target" \
                "$_src" \
                "$_target_filename" \
                "$_target_os" \
                "$_target_arch"
        case $? in
        10)
                FS::remove_silently "$_src"
                I18N_Status_Print_Package_Assembler_Exec_Skipped
                return 0
                ;;
        0)
                ;;
        *)
                I18N_Status_Print_Package_Assembler_Exec_Failed
                return 1
                ;;
        esac


        # archive the assembled payload
        for __recipe in "${_src}/"*.wxs; do
                if [ ! -e "$__recipe" ]; then
                        continue
                fi

                FS::is_file "$__recipe"
                if [ $? -ne 0 ]; then
                        continue
                fi


                # register for packaging in parallel
                I18N_Status_Print_Package_Parallelism_Register "$__recipe"
                __log="${__recipe##*/}"
                __log="${__log%.wxs*}"
                __log="${__control_directory}/msi-wxs_${__log}.log"
                FS::append_file "$__parallel_control" "\
${__recipe}|${_dest}|${__log}
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done

        I18N_Status_Print_Package_Parallelism_Run
        FS::is_file "$__parallel_control"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Package_Parallelism_Run_Skipped
                return 0
        fi

        SYNC::parallel_exec "SUBROUTINE_Package_MSI" "$__parallel_control"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Package_Parallelism_Run_Failed
                return 1
        fi

        for __log in "${__control_directory}/"*.log; do
                if [ ! -e "$__log" ]; then
                        continue
                fi

                I18N_Status_Print_Package_Parallelism_Logdump "${__log##*/}"
                old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        I18N_Status_Print_Plain "$__line"
                done < "$__log"
                IFS="$old_IFS" && unset old_IFS
                I18N_Status_Print_Newline
        done


        # report status
        return 0
}
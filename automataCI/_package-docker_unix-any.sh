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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/docker.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




PACKAGE_Run_DOCKER() {
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


        # validate input
        I18N_Check_Availability "DOCKER"
        DOCKER_Is_Available
        case $? in
        2|3)
                I18N_Check_Incompatible
                return 0
                ;;
        0)
                # accepted
                ;;
        *)
                I18N_Check_Failed_Skipped
                return 0
                ;;
        esac

        I18N_Check_Login "DOCKER"
        DOCKER_Check_Login
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # prepare workspace and required values
        I18N_Create_Package "DOCKER"
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/docker.txt"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/packagers-docker-${_src}"
        I18N_Remake "$_src"
        FS_Remake_Directory "$_src"
        if [ $? -ne 0 ]; then
                I18N_Remake_Failed
                return 1
        fi


        # copy all complimentary files to the workspace
        cmd="PACKAGE_Assemble_DOCKER_Content"
        I18N_Check_Function "$cmd"
        OS_Is_Command_Available "$cmd"
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi

        I18N_Assemble_Package
        "$cmd" "$_target" "$_src" "$_target_filename" "$_target_os" "$_target_arch"
        case $? in
        10)
                I18N_Assemble_Skipped
                FS_Remove_Silently "$_src"
                return 0
                ;;
        0)
                # accepted
                ;;
        *)
                I18N_Assemble_Failed
                return 1
                ;;
        esac


        # check required files
        I18N_Check "${_src}/Dockerfile"
        FS_Is_File "${_src}/Dockerfile"
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # change location into the workspace
        __current_path="$PWD" && cd "$_src"


        # archive the assembled payload
        I18N_Package "$_target_path"
        DOCKER_Create \
                "$_target_path" \
                "$_target_os" \
                "$_target_arch" \
                "$PROJECT_CONTAINER_REGISTRY" \
                "$PROJECT_SKU" \
                "$PROJECT_VERSION"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                I18N_Package_Failed "$_target_path"
                return 1
        fi


        # logout
        I18N_Logout "DOCKER"
        DOCKER_Logout
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                I18N_Logout_Failed
                return 1
        fi


        # clean up dangling images
        I18N_Clean "DOCKER"
        DOCKER_Clean_Up
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                I18N_Clean_Failed
                return 1
        fi


        # head back to current directory
        cd "$__current_path" && unset __current_path


        # report status
        return 0
}

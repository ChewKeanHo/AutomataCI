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




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/strings.sh"




# source locally provided functions
__recipe="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}"
__recipe="${__recipe}/notarize_unix-any.sh"
FS::is_file "$__recipe"
if [ $? -eq 0 ]; then
        OS::print_status info "sourcing content assembling functions: ${__recipe}\n"
        . "$__recipe"
        if [ $? -ne 0 ]; then
                OS::print_status error "Sourcing failed\n"
                return 1
        fi
fi




# source from Python and overrides existing
if [ ! -z "$PROJECT_PYTHON" ]; then
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/${PROJECT_PATH_CI}"
        __recipe="${__recipe}/notarize_unix-any.sh"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info \
                        "sourcing Python content assembling functions: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Sourcing failed\n"
                        return 1
                fi
        fi
fi




# source from Go and overrides existing
if [ ! -z "$PROJECT_GO" ]; then
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_GO}/${PROJECT_PATH_CI}"
        __recipe="${__recipe}/notarize_unix-any.sh"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info "sourcing Go content assembling functions: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Sourcing failed\n"
                        return 1
                fi
        fi
fi




# source from C and overrides existing
if [ ! -z "$PROJECT_C" ]; then
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_C}/${PROJECT_PATH_CI}"
        __recipe="${__recipe}/notarize_unix-any.sh"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info "sourcing C content assembling functions: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Sourcing failed\n"
                        return 1
                fi
        fi
fi




# source from Nim and overrides existing
if [ ! -z "$PROJECT_NIM" ]; then
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_NIM}/${PROJECT_PATH_CI}"
        __recipe="${__recipe}/notarize_unix-any.sh"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info "sourcing Nim content assembling functions: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Sourcing failed\n"
                        return 1
                fi
        fi
fi




# source from Angular and overrides existing
if [ ! -z "$PROJECT_ANGULAR" ]; then
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_ANGULAR}/${PROJECT_PATH_CI}"
        __recipe="${__recipe}/notarize_unix-any.sh"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info "sourcing Angular content assembling functions: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Sourcing failed\n"
                        return 1
                fi
        fi
fi




# begin notarize
for i in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"/*; do
        if [ -d "$i" ]; then
                continue
        fi

        if [ ! -f "$i" ]; then
                continue
        fi


        # parse build candidate
        OS::print_status info "detected ${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${i}\n"
        TARGET_FILENAME="${i##*${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/}"
        TARGET_FILENAME="${TARGET_FILENAME%.*}"
        TARGET_OS="${TARGET_FILENAME##*_}"
        TARGET_FILENAME="${TARGET_FILENAME%%_*}"
        TARGET_ARCH="${TARGET_OS##*-}"
        TARGET_OS="${TARGET_OS%%-*}"

        if [ -z "$TARGET_OS" ] || [ -z "$TARGET_ARCH" ] || [ -z "$TARGET_FILENAME" ]; then
                OS::print_status warning "failed to parse file. Skipping.\n"
                continue
        fi

        STRINGS::has_prefix "$PROJECT_SKU" "$TARGET_FILENAME"
        if [ $? -ne 0 ]; then
                OS::print_status warning "incompatible file. Skipping.\n"
                continue
        fi


        # execute
        OS::is_command_available "NOTARY::certify"
        if [ $? -eq 0 ]; then
                NOTARY::certify \
                        "$i" \
                        "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}" \
                        "$TARGET_FILENAME" \
                        "$TARGET_OS" \
                        "$TARGET_ARCH"
                case $? in
                12)
                        OS::print_status warning "simulating successful notarization...\n"
                        ;;
                11)
                        OS::print_status warning "notarization unavailable. Skipping...\n"
                        ;;
                10)
                        OS::print_status warning "notarization is not applicable. Skipping...\n"
                        ;;
                0)
                        OS::print_status success "\n\n"
                        ;;
                *)
                        OS::print_status error "notarization failed.\n"
                        return 1
                        ;;
                esac
        else
                OS::print_status warning "NOTARY::certify is unavailable. Skipping...\n"
        fi
done




# report status
return 0
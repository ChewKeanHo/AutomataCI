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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/sync.sh"

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-archive_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-cargo_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-changelog_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-chocolatey_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-deb_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-docker_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-flatpak_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-homebrew_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-ipk_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-pypi_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-rpm_unix-any.sh"




# source locally provided functions
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-sourcing_unix-any.sh"




# 1-time setup job required materials
DEST="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
OS::print_status info "remaking package directory: $DEST\n"
FS::remake_directory "$DEST"
if [ $? -ne 0 ]; then
        OS::print_status error "remake failed.\n"
        return 1
fi


FILE_CHANGELOG_MD="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/CHANGELOG.md"
FILE_CHANGELOG_DEB="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/deb/changelog.gz"
PACKAGE::run_changelog "$FILE_CHANGELOG_MD" "$FILE_CHANGELOG_DEB"
if [ $? -ne 0 ]; then
        return 1
fi


OS::print_status plain "\n"




# prepare for parallel package
__log_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/packagers"
OS::print_status info "remaking packagers' log directory: ${__log_directory}\n"
FS::remake_directory "$__log_directory"
if [ ! -d "$__log_directory" ]; then
        OS::print_status error "remake failed.\n"
        return 1
fi

__control_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/packagers-parallel"
OS::print_status info "remaking packagers' control directory: ${__log_directory}\n"
FS::remake_directory "$__control_directory"
if [ ! -d "$__control_directory" ]; then
        OS::print_status error "remake failed.\n"
        return 1
fi

__parallel_control="${__control_directory}/control-parallel.txt"
FS::remove_silently "$__parallel_control"

__series_control="${__control_directory}/control-series.txt"
FS::remove_silently "$__series_control"


SUBROUTINE::package() {
        #__line="$1"


        # parse input
        __command="${1##*|}"
        __arguments="${1%|*}"

        __log="${__arguments##*|}"
        __arguments="${__arguments%|*}|"

        __subject="${__log##*/}"
        __subject="${__subject%.*}"


        # execute
        OS::print_status info "packaging ${__subject}...\n"

        FS::remove_silently "$__log"

        $__command "$__arguments" &> "$__log"
        if [ $? -ne 0 ]; then
                OS::print_status error "package failed - ${__subject}\n"
                return 1
        fi


        # report status
        return 0
}




# register for parallel packaging
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

        OS::print_status info "registering ${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${i}\n"
        __common="${DEST}|${i}|${TARGET_FILENAME}|${TARGET_OS}|${TARGET_ARCH}"

        __log="${__log_directory}/archive_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__parallel_control" "\
${__common}|${__log}|PACKAGE::run_archive
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __log="${__log_directory}/chocolatey_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__parallel_control" "\
${__common}|${__log}|PACKAGE::run_chocolatey
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __log="${__log_directory}/homebrew_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__parallel_control" "\
${__common}|${__log}|PACKAGE::run_homebrew
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __log="${__log_directory}/deb_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__parallel_control" "\
${__common}|${FILE_CHANGELOG_DEB}|${__log}|PACKAGE::run_deb
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __log="${__log_directory}/ipk_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__parallel_control" "\
${__common}|${__log}|PACKAGE::run_ipk
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __log="${__log_directory}/rpm_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__parallel_control" "\
${__common}|${__log}|PACKAGE::run_rpm
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __flatpak_path="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${PROJECT_PATH_RELEASE}/flatpak"
        __log="${__log_directory}/flatpak_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__series_control" "\
${__common}|${__flatpak_path}|${__log}|PACKAGE::run_flatpak
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __log="${__log_directory}/pypi_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__parallel_control" "\
${__common}|${__log}|PACKAGE::run_pypi
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __log="${__log_directory}/cargo_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__parallel_control" "\
${__common}|${__log}|PACKAGE::run_cargo
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __log="${__log_directory}/docker_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__series_control" "\
${__common}|${__log}|PACKAGE::run_docker
"
        if [ $? -ne 0 ]; then
                return 1
        fi
done


OS::print_status plain "\n"
OS::print_status info "executing all parallel runs...\n"
SYNC::parallel_exec "SUBROUTINE::package" "$__parallel_control"
if [ $? -ne 0 ]; then
        OS::print_status error "execute failed.\n\n"
        return 1
fi


OS::print_status plain "\n"
OS::print_status info "executing all series runs...\n"
SYNC::series_exec "SUBROUTINE::package" "$__series_control"
if [ $? -ne 0 ]; then
        OS::print_status error "execute failed.\n\n"
        return 1
fi




# report status
OS::print_status success "\n\n"
return 0

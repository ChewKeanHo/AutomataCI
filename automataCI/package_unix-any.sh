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

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/io/sync.sh"

. "${LIBS_AUTOMATACI}/services/i18n/status-file.sh"
. "${LIBS_AUTOMATACI}/services/i18n/status-job-package.sh"
. "${LIBS_AUTOMATACI}/services/i18n/status-run.sh"
. "${LIBS_AUTOMATACI}/services/i18n/status-sync.sh"

. "${LIBS_AUTOMATACI}/_package-archive_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-cargo_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-changelog_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-chocolatey_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-deb_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-docker_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-flatpak_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-homebrew_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-ipk_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-msi_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-pypi_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-rpm_unix-any.sh"




# source locally provided functions
. "${LIBS_AUTOMATACI}/_package-sourcing_unix-any.sh"




# 1-time setup job required materials
DEST="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
I18N_Status_Print_Package_Directory_Remake "$DEST"
FS::remake_directory "$DEST"
if [ $? -ne 0 ]; then
        I18N_Status_Print_Package_Remake_Failed
        return 1
fi


FILE_CHANGELOG_MD="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/CHANGELOG.md"
FILE_CHANGELOG_DEB="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/deb/changelog.gz"
PACKAGE::run_changelog "$FILE_CHANGELOG_MD" "$FILE_CHANGELOG_DEB"
if [ $? -ne 0 ]; then
        return 1
fi


I18N_Status_Print_Newline




# prepare for parallel package
__log_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/packagers"
I18N_Status_Print_Package_Directory_Log_Remake "$__log_directory"
FS::remake_directory "$__log_directory"
if [ ! -d "$__log_directory" ]; then
        I18N_Status_Print_Package_Remake_Failed
        return 1
fi

__control_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/packagers-parallel"
I18N_Status_Print_Package_Directory_Control_Remake "${__control_directory}"
FS::remake_directory "$__control_directory"
if [ ! -d "$__control_directory" ]; then
        I18N_Status_Print_Package_Remake_Failed
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
        I18N_Status_Print_Package_Exec "$__subject"
        FS::remove_silently "$__log"

        $__command "$__arguments" &> "$__log"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Package_Exec_Failed "${__subject}"
                return 1
        fi


        # report status
        return 0
}




# begin registering packagers
for i in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"/*; do
        FS::is_file "$i"
        if [ $? -ne 0 ]; then
                continue
        fi


        # parse build candidate
        I18N_Status_Print_File_Detected "$i"
        TARGET_FILENAME="${i##*${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/}"
        TARGET_FILENAME="${TARGET_FILENAME%.*}"
        TARGET_OS="${TARGET_FILENAME##*_}"
        TARGET_FILENAME="${TARGET_FILENAME%%_*}"
        TARGET_ARCH="${TARGET_OS##*-}"
        TARGET_OS="${TARGET_OS%%-*}"

        if [ "$(STRINGS_Is_Empty "$TARGET_OS")" -eq 0 ] ||
                [ "$(STRINGS_Is_Empty "$TARGET_ARCH")" -eq 0 ] ||
                [ "$(STRINGS_Is_Empty "$TARGET_FILENAME")" -eq 0 ]; then
                I18N_Status_Print_File_Bad_Stat_Skipped
                continue
        fi

        STRINGS::has_prefix "$PROJECT_SKU" "$TARGET_FILENAME"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_File_Incompatible_Skipped
                continue
        fi

        I18N_Status_Print_Sync_Register "$i"
        __common="${DEST}|${i}|${TARGET_FILENAME}|${TARGET_OS}|${TARGET_ARCH}"

        __log="${__log_directory}/archive_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__parallel_control" "\
${__common}|${__log}|PACKAGE::run_archive
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

        __log="${__log_directory}/chocolatey_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__parallel_control" "\
${__common}|${__log}|PACKAGE::run_chocolatey
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

        __log="${__log_directory}/docker_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__series_control" "\
${__common}|${__log}|PACKAGE_Run_Docker
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __flatpak_path="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${PROJECT_PATH_RELEASE}/flatpak"
        __log="${__log_directory}/flatpak_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__series_control" "\
${__common}|${__flatpak_path}|${__log}|PACKAGE_Run_Flatpak
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

        __log="${__log_directory}/ipk_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__parallel_control" "\
${__common}|${__log}|PACKAGE::run_ipk
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __log="${__log_directory}/msi_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__series_control" "\
${__common}|${__log}|PACKAGE_Run_MSI
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

        __log="${__log_directory}/rpm_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
        FS::append_file "$__parallel_control" "\
${__common}|${__log}|PACKAGE::run_rpm
"
        if [ $? -ne 0 ]; then
                return 1
        fi
done


I18N_Status_Print_Sync_Exec_Parallel
FS::is_file "$__parallel_control"
if [ $? -eq 0 ]; then
        SYNC::parallel_exec "SUBROUTINE::package" "$__parallel_control"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Sync_Exec_Failed
                return 1
        fi
fi


I18N_Status_Print_Sync_Exec_Series
FS::is_file "$__series_control"
if [ $? -eq 0 ]; then
        SYNC::series_exec "SUBROUTINE::package" "$__series_control"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Sync_Exec_Failed
                return 1
        fi
fi




# report status
I18N_Status_Print_Run_Successful
return 0

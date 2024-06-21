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




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/io/sync.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/flatpak.sh"
. "${LIBS_AUTOMATACI}/services/publishers/homebrew.sh"
. "${LIBS_AUTOMATACI}/services/versioners/git.sh"

. "${LIBS_AUTOMATACI}/_package-archive_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-cargo_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-changelog_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-chocolatey_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-citation_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-deb_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-docker_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-flatpak_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-homebrew_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-ipk_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-lib_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-msi_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-pdf_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-pypi_unix-any.sh"
. "${LIBS_AUTOMATACI}/_package-rpm_unix-any.sh"




# source locally provided functions
. "${LIBS_AUTOMATACI}/_package-sourcing_unix-any.sh"




# 1-time setup job required materials
DEST="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
I18N_Remake "$DEST"
FS_Remake_Directory "$DEST"
if [ $? -ne 0 ]; then
        I18N_Remake_Failed
        return 1
fi


if [ "$(STRINGS_Is_Empty "$PROJECT_HOMEBREW_URL")" -ne 0 ]; then
        HOMEBREW_WORKSPACE="packagers-homebrew-${PROJECT_SKU}"
        I18N_Setup "$HOMEBREW_WORKSPACE"
        HOMEBREW_WORKSPACE="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${HOMEBREW_WORKSPACE}"
        FS_Remake_Directory "$HOMEBREW_WORKSPACE"
        if [ $? -ne 0 ]; then
                I18N_Setup_Failed
                return 1
        fi
fi


if [ "$(STRINGS_Is_Empty "$PROJECT_MSI_INSTALL_DIRECTORY")" -ne 0 ]; then
        MSI_WORKSPACE="packagers-msi-${PROJECT_SKU}"
        I18N_Setup "$MSI_WORKSPACE"
        MSI_WORKSPACE="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${MSI_WORKSPACE}"
        FS_Remake_Directory "$MSI_WORKSPACE"
        if [ $? -ne 0 ]; then
                I18N_Setup_Failed
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_MSI_REGISTRY_KEY") -eq 0 ]; then
                PROJECT_MSI_REGISTRY_KEY="\
Software\\\\${PROJECT_SCOPE}\\\\InstalledProducts\\\\${PROJECT_SKU_TITLECASE}"
        fi
fi


if [ "$(STRINGS_Is_Empty "$PROJECT_FLATPAK_URL")" -ne 0 ]; then
        FLATPAK_REPO="flatpak-repo"
        I18N_Setup "$FLATPAK_REPO"
        FLATPAK_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${FLATPAK_REPO}"
        FS_Remove_Silently "$FLATPAK_REPO"

        if [ $(STRINGS_Is_Empty "$PROJECT_FLATPAK_REPO") -ne 0 ] &&
                [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_REPO") -eq 0 ]; then
                # version controlled repository supplied; AND
                # single unified repository is not enabled
                FS_Make_Housing_Directory "$FLATPAK_REPO"
                GIT_Clone_Repo \
                        "$PROJECT_PATH_ROOT" \
                        "$PROJECT_PATH_TEMP" \
                        "$PWD" \
                        "$PROJECT_FLATPAK_REPO" \
                        "$PROJECT_SIMULATE_RUN" \
                        "$(FS_Get_File "$FLATPAK_REPO")" \
                        "$PROJECT_FLATPAK_REPO_BRANCH"
                if [ $? -ne 0 ]; then
                        I18N_Setup_Failed
                        return 1
                fi

                if [ $(STRINGS_Is_Empty "$PROJECT_FLATPAK_PATH") -ne 0 ]; then
                        FLATPAK_REPO="${FLATPAK_REPO}/${PROJECT_FLATPAK_PATH}"
                fi
        fi

        FS_Make_Directory "$FLATPAK_REPO"
        if [ $? -ne 0 ]; then
                I18N_Setup_Failed
                return 1
        fi
fi


FILE_CHANGELOG_MD="${PROJECT_SKU}-CHANGELOG_${PROJECT_VERSION}.md"
FILE_CHANGELOG_MD="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/${FILE_CHANGELOG_MD}"
FILE_CHANGELOG_DEB="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/packagers-changelog/deb.gz"
PACKAGE_Run_CHANGELOG "$FILE_CHANGELOG_MD" "$FILE_CHANGELOG_DEB"
if [ $? -ne 0 ]; then
        return 1
fi


FILE_CITATION_CFF="${PROJECT_SKU}-CITATION_${PROJECT_VERSION}.cff"
FILE_CITATION_CFF="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/${FILE_CITATION_CFF}"
PACKAGE_Run_CITATION "$FILE_CITATION_CFF"
if [ $? -ne 0 ]; then
        return 1
fi


I18N_Newline




# prepare for parallel package
__log_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/packagers"
I18N_Remake "$__log_directory"
FS_Remake_Directory "$__log_directory"
FS_Is_Directory "$__log_directory"
if [ $? -ne 0 ]; then
        I18N_Remake_Failed
        return 1
fi

__control_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/packagers-parallel"
I18N_Remake "${__control_directory}"
FS_Remake_Directory "$__control_directory"
FS_Is_Directory "$__control_directory"
if [ $? -ne 0 ]; then
        I18N_Remake_Failed
        return 1
fi

__parallel_control="${__control_directory}/control-parallel.txt"
FS_Remove_Silently "$__parallel_control"

__serial_control="${__control_directory}/control-serial.txt"
FS_Remove_Silently "$__serial_control"


SUBROUTINE_Package() {
        #__line="$1"


        # parse input
        __command="${1##*|}"
        __arguments="${1%|*}"

        __log="${__arguments##*|}"
        __arguments="${__arguments%|*}|"

        __subject="${__log##*/}"
        __subject="${__subject%.*}"


        # execute
        I18N_Package "$__subject"
        FS_Remove_Silently "$__log"

        $__command "$__arguments" &> "$__log"
        if [ $? -ne 0 ]; then
                I18N_Package_Failed
                return 1
        fi


        # report status
        return 0
}




# begin registering packagers
FS_Is_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
if [ $? -eq 0 ]; then
for i in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"/*; do
        FS_Is_File "$i"
        if [ $? -ne 0 ]; then
                continue
        fi


        # parse build candidate
        I18N_Detected "$i"
        TARGET_FILENAME="${i##*${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/}"
        TARGET_FILENAME="${TARGET_FILENAME%.*}"
        TARGET_OS="${TARGET_FILENAME##*_}"
        TARGET_FILENAME="${TARGET_FILENAME%%_*}"
        TARGET_ARCH="${TARGET_OS##*-}"
        TARGET_ARCH="${TARGET_ARCH%%.*}"
        TARGET_OS="${TARGET_OS%%-*}"
        TARGET_OS="${TARGET_OS%%.*}"

        if [ "$(STRINGS_Is_Empty "$TARGET_OS")" -eq 0 ] ||
                [ "$(STRINGS_Is_Empty "$TARGET_ARCH")" -eq 0 ] ||
                [ "$(STRINGS_Is_Empty "$TARGET_FILENAME")" -eq 0 ]; then
                I18N_File_Has_Bad_Stat_Skipped
                continue
        fi

        STRINGS_Has_Prefix "$PROJECT_SKU" "$TARGET_FILENAME"
        if [ $? -ne 0 ]; then
                STRINGS_Has_Prefix "lib${PROJECT_SKU}" "$TARGET_FILENAME"
                if [ $? -ne 0 ]; then
                        I18N_Is_Incompatible_Skipped "$TARGET_FILENAME"
                        continue
                fi
        fi

        __common="${DEST}|${i}|${TARGET_FILENAME}|${TARGET_OS}|${TARGET_ARCH}"


        # begin registrations
        I18N_Sync_Register "$i"

        if [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_ARCHIVE") -ne 0 ]; then
                __log="archive_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                __log="${__log_directory}/${__log}"
                FS_Append_File "$__parallel_control" "\
${__common}|${__log}|PACKAGE_Run_ARCHIVE
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_RUST") -ne 0 ]; then
                __log="cargo_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                __log="${__log_directory}/${__log}"
                FS_Append_File "$__parallel_control" "\
${__common}|${__log}|PACKAGE_Run_CARGO
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        # NOTE: chocolatey only serve windows
        if [ $(STRINGS_Is_Empty "$PROJECT_CHOCOLATEY_URL") -ne 0 ]; then
                case "$TARGET_OS" in
                any|windows)
                        __log="chocolatey_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                        __log="${__log_directory}/${__log}"
                        FS_Append_File "$__parallel_control" "\
${__common}|${__log}|PACKAGE_Run_CHOCOLATEY
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                        ;;
                *)
                        ;;
                esac
        fi

        # NOTE: deb does not work in windows or mac
        if [ $(STRINGS_Is_Empty "$PROJECT_DEB_URL") -ne 0 ]; then
                case "$TARGET_OS" in
                windows|darwin)
                        ;;
                *)
                        __log="deb_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                        __log="${__log_directory}/${__log}"
                        FS_Append_File "$__parallel_control" "\
${__common}|${FILE_CHANGELOG_DEB}|${__log}|PACKAGE_Run_DEB
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                        ;;
                esac
        fi

        # NOTE: container only serve windows and linux
        if [ $(STRINGS_Is_Empty "$PROJECT_CONTAINER_REGISTRY") -ne 0 ]; then
                case "$TARGET_OS" in
                any|linux|windows)
                        __log="docker_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                        __log="${__log_directory}/${__log}"
                        FS_Append_File "$__serial_control" "\
${__common}|${__log}|PACKAGE_Run_DOCKER
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                        ;;
                *)
                        ;;
                esac
        fi

        # NOTE: flatpak only serve linux
        FLATPAK_Is_Available
        if [ $? -eq 0 ] && [ $(STRINGS_Is_Empty "$PROJECT_FLATPAK_URL") -ne 0 ]; then
                case "$TARGET_OS" in
                any|linux)
                        __log="flatpak_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                        __log="${__log_directory}/${__log}"
                        FS_Append_File "$__serial_control" "\
${__common}|${FLATPAK_REPO}|${__log}|PACKAGE_Run_FLATPAK
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                        ;;
                *)
                        ;;
                esac
        fi

        # NOTE: homebrew only serve linux and mac
        if [ $(STRINGS_Is_Empty "$PROJECT_HOMEBREW_URL") -ne 0 ]; then
                case "$TARGET_OS" in
                any|darwin|linux)
                        __log="homebrew_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                        __log="${__log_directory}/${__log}"
                        FS_Append_File "$__parallel_control" "\
${__common}|${HOMEBREW_WORKSPACE}|${__log}|PACKAGE_Run_HOMEBREW
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                        ;;
                *)
                        ;;
                esac
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_IPK") -ne 0 ]; then
                __log="ipk_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                __log="${__log_directory}/${__log}"
                FS_Append_File "$__parallel_control" "\
${__common}|${__log}|PACKAGE_Run_IPK
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        if [ $(FS_Is_Target_A_Library "$i") -eq 0 ] &&
                [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_ARCHIVE") -ne 0 ]; then
                __log="lib_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                __log="${__log_directory}/${__log}"
                FS_Append_File "$__parallel_control" "\
${__common}|${__log}|PACKAGE_Run_LIB
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        # NOTE: MSI only works in windows
        if [ $(STRINGS_Is_Empty "$PROJECT_MSI_INSTALL_DIRECTORY") -ne 0 ]; then
                case "$TARGET_OS" in
                any|windows)
                        __log="msi_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                        __log="${__log_directory}/${__log}"
                        FS_Append_File "$__parallel_control" "\
${__common}|${MSI_WORKSPACE}|${__log}|PACKAGE_Run_MSI
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                        ;;
                *)
                        ;;
                esac

        fi

        if [ $(FS_Is_Target_A_PDF "$i") -eq 0 ]; then
                __log="pdf_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                __log="${__log_directory}/${__log}"
                FS_Append_File "$__parallel_control" "\
${__common}|${__log}|PACKAGE_Run_PDF
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PYTHON") -ne 0 ]; then
                __log="pypi_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                __log="${__log_directory}/${__log}"
                FS_Append_File "$__parallel_control" "\
${__common}|${__log}|PACKAGE_Run_PYPI
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        # NOTE: RPM only serve linux
        if [ $(STRINGS_Is_Empty "$PROJECT_RPM_URL") -ne 0 ]; then
                case "$TARGET_OS" in
                any|linux)
                        __log="rpm_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
                        __log="${__log_directory}/${__log}"
                        FS_Append_File "$__parallel_control" "\
${__common}|${__log}|PACKAGE_Run_RPM
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                        ;;
                *)
                        ;;
                esac
        fi
done
fi


I18N_Sync_Run
FS_Is_File "$__parallel_control"
if [ $? -eq 0 ]; then
        SYNC_Exec_Parallel "SUBROUTINE_Package" "$__parallel_control"
        if [ $? -ne 0 ]; then
                I18N_Sync_Failed
                return 1
        fi
fi


if [ $(STRINGS_Is_Empty "$PROJECT_HOMEBREW_URL") -ne 0 ]; then
        I18N_Newline
        I18N_Newline

        __dest="${PROJECT_SKU}.rb"
        I18N_Export "$__dest"
        __dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/${__dest}"
        HOMEBREW_Seal "$__dest" \
                "${PROJECT_SKU}-homebrew_${PROJECT_VERSION}_any-any.tar.xz" \
                "$HOMEBREW_WORKSPACE" \
                "$PROJECT_SKU" \
                "$PROJECT_PITCH" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_LICENSE" \
                "$PROJECT_HOMEBREW_URL"
        if [ $? -ne 0 ];then
                I18N_Export_Failed
                return 1
        fi
fi


if [ "$(STRINGS_Is_Empty "$PROJECT_MSI_INSTALL_DIRECTORY")" -ne 0 ]; then
        I18N_Newline
        I18N_Newline

        # sort any arch into others
        PACKAGE_Sort_MSI "$MSI_WORKSPACE"
        if [ $? -ne 0 ];then
                return 1
        fi

        # seal all MSI packages
        for _candidate in "${MSI_WORKSPACE}/"*; do
                FS_Is_Directory "$_candidate"
                if [ $? -ne 0 ]; then
                        continue
                fi

                I18N_Newline
                PACKAGE_Seal_MSI "$_candidate" "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
                if [ $? -ne 0 ];then
                        return 1
                fi
        done
fi


I18N_Sync_Run_Series
FS_Is_File "$__serial_control"
if [ $? -eq 0 ]; then
        SYNC_Exec_Serial "SUBROUTINE_Package" "$__serial_control"
        if [ $? -ne 0 ]; then
                I18N_Sync_Failed
                return 1
        fi
fi




# report status
I18N_Run_Successful
return 0

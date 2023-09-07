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




# (0) initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/strings.sh"

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-changelog_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-archive_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-deb_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-rpm_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-flatpak_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-pypi_unix-any.sh"




# (1) source locally provided functions
DEST="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}"
DEST="${DEST}/package_unix-any.sh"
OS::print_status info "sourcing content assembling functions from: ${DEST}\n"
FS::is_target_exist "$DEST"
if [ $? -ne 0 ]; then
        OS::print_status error "Sourcing failed\n"
        return 1
fi
. "$DEST"




# (2) 1-time setup job required materials
DEST="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
OS::print_status info "remaking package directory: $DEST\n"
FS::remake_directory "$DEST"
if [ $? -ne 0 ]; then
        OS::print_status error "remake failed.\n"
        return 1
fi


FILE_CHANGELOG_MD="${PROJECT_PATH_ROOT}/MARKDOWN.md"
FILE_CHANGELOG_DEB="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/deb/changelog.gz"
PACKAGE::run_changelog "$FILE_CHANGELOG_MD" "$FILE_CHANGELOG_DEB"
if [ $? -ne 0 ]; then
        return 1
fi




# (3) begin packaging
for i in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"/*; do
        if [ -d "$i" ]; then
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

        PACKAGE::run_archive \
                "$DEST" \
                "$i" \
                "$TARGET_FILENAME" \
                "$TARGET_OS" \
                "$TARGET_ARCH"
        if [ $? -ne 0 ]; then
                return 1
        fi

        PACKAGE::run_deb \
                "$DEST" \
                "$i" \
                "$TARGET_FILENAME" \
                "$TARGET_OS" \
                "$TARGET_ARCH" \
                "$FILE_CHANGELOG_DEB"
        if [ $? -ne 0 ]; then
                return 1
        fi

        PACKAGE::run_rpm \
                "$DEST" \
                "$i" \
                "$TARGET_FILENAME" \
                "$TARGET_OS" \
                "$TARGET_ARCH"
        if [ $? -ne 0 ]; then
                return 1
        fi

        PACKAGE::run_flatpak \
                "$DEST" \
                "$i" \
                "$TARGET_FILENAME" \
                "$TARGET_OS" \
                "$TARGET_ARCH"
        if [ $? -ne 0 ]; then
                return 1
        fi

        PACKAGE::run_pypi \
                "$DEST" \
                "$i" \
                "$TARGET_FILENAME" \
                "$TARGET_OS" \
                "$TARGET_ARCH"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report job verdict
        OS::print_status success "\n\n"
done
return 0

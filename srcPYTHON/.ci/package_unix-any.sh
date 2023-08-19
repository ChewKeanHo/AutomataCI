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
        >&2 printf "[ ERROR ] - Please source from ci.cmd instead!\n"
        return 1
fi




# (1) safety checking control surfaces
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/tar.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/zip.sh"
CheckTarIsAvailable
if [ $? -ne 0 ]; then
        return 1
fi

CheckXZIsAvailable
if [ $? -ne 0 ]; then
        return 1
fi

CheckZipIsAvailable
if [ $? -ne 0 ]; then
        return 1
fi


# (2) clean up destination path
dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
rm -rf "$dest" &> /dev/null
mkdir -p "$dest"


# (3) begin packaging
for i in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"/*; do
        if [ -d "$i" ]; then
                continue
        fi


        # (3.1) parse build candidate
        TARGET_FILENAME="${i##*${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/}"
        TARGET_FILENAME="${TARGET_FILENAME%.*}"
        TARGET_OS="${TARGET_FILENAME##*_}"
        TARGET_FILENAME="${TARGET_FILENAME%%_*}"
        TARGET_ARCH="${TARGET_OS##*-}"
        TARGET_OS="${TARGET_OS%%-*}"

        if [ -z "$TARGET_OS" ] || [ -z "$TARGET_ARCH" ] || [ -z "$TARGET_FILENAME" ]; then
                >&2 printf "[ WARNING ] detected "$i" but failed to parse. Skipping."
                continue
        fi


        # (3.2) archive into tar.xz / zip package
        src="archive_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}"
        >&2 printf "[ INFO ] Processing ${TARGET_FILENAME} for ${src}\n"
        src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${src}"
        dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"

        # (3.2.1) copy necessary complimentary files to the package
        rm -rf "$src" &> /dev/null
        mkdir -p "$src"
        cp "$i" "${src}/${TARGET_FILENAME}"
        cp "${PROJECT_PATH_ROOT}/USER-GUIDES-EN.pdf" "${src}/."
        cp "${PROJECT_PATH_ROOT}/LICENSE-EN.pdf" "${src}/."

        # (3.2.2) archive accordingly
        case "$TARGET_OS" in
        windows)
                mv "${src}/${TARGET_FILENAME}" "${src}/${TARGET_FILENAME}.exe"
                CreateZIP \
                        "$src" \
                        "${dest}/${TARGET_FILENAME}_windows-${TARGET_ARCH}.zip"
                ;;
        *)
                CreateTARXZ \
                        "$src" \
                        "${dest}/${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.tar.xz"
                ;;
        esac
        >&2 printf "[ SUCCESS ]\n\n"
done

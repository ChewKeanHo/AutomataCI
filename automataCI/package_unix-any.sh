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

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




# (1) execute tech-specific CI job
recipe="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}"
recipe="${recipe}/package_unix-any.sh"
if [ -f "$recipe" ]; then
        . "$recipe"
        return $?
fi




# (2) no custom job recipe. Use default job executions...
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/archive/tar.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/archive/zip.sh"




# (3) safety checking control surfaces
TARXZ::is_available
if [ $? -ne 0 ]; then
        OS::print_status error "'tar' command is not available.\n"
        return 1
fi

ZIP::is_available
if [ $? -ne 0 ]; then
        OS::print_status error "'zip' command is not available.\n"
        return 1
fi




# (4) clean up destination path
dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
OS::print_status info "remaking package directory: $dest\n"
FS::remake_directory "$dest"
if [ $? -ne 0 ]; then
        OS::print_status error "remake failed.\n"
        return 1
fi




# (5) begin packaging
for i in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"/*; do
        if [ -d "$i" ]; then
                continue
        fi
        OS::print_status info "detected ${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${i}\n"


        # (5.1) parse build candidate
        TARGET_FILENAME="${i##*${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/}"
        TARGET_FILENAME="${TARGET_FILENAME%.*}"
        TARGET_OS="${TARGET_FILENAME##*_}"
        TARGET_FILENAME="${TARGET_FILENAME%%_*}"
        TARGET_ARCH="${TARGET_OS##*-}"
        TARGET_OS="${TARGET_OS%%-*}"

        if [ -z "$TARGET_OS" ] || [ -z "$TARGET_ARCH" ] || [ -z "$TARGET_FILENAME" ]; then
                OS::print_status warning "detected "$i" but failed to parse. Skipping.\n"
                continue
        fi


        # (5.2) archive into tar.xz / zip package
        src="archive_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}"
        src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${src}"
        OS::print_status info "processing ${src} for ${TARGET_OS}-${TARGET_ARCH}\n"
        dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"

        # (5.2.1) copy necessary complimentary files to the package
        OS::print_status info "remaking workspace directory $src\n"
        FS::remake_directory "$src"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi

        file="$i"
        OS::print_status info "copying $file to $src\n"
        FS::copy_file "$file" "${src}/${TARGET_FILENAME}"
        if [ $? -ne 0 ]; then
                OS::print_status error "copy failed.\n"
                return 1
        fi

        file="${PROJECT_PATH_ROOT}/USER-GUIDES-EN.pdf"
        OS::print_status info "copying $file to $src\n"
        FS::copy_file "$file" "${src}/."
        if [ $? -ne 0 ]; then
                OS::print_status error "copy failed.\n"
                return 1
        fi

        file="${PROJECT_PATH_ROOT}/LICENSE-EN.pdf"
        OS::print_status info "copying $file to $src\n"
        FS::copy_file "$file" "${src}/."
        if [ $? -ne 0 ]; then
                OS::print_status error "copy failed.\n"
                return 1
        fi

        # (5.2.2) archive accordingly
        case "$TARGET_OS" in
        windows)
                file="${src}/${TARGET_FILENAME}"
                OS::print_status info "renaming ${file} to ${file}.exe\n"
                FS::rename "${file}" "${file}.exe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "packaging failed.\n"
                        return 1
                fi

                dest="${dest}/${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.zip"
                OS::print_status info "packaging $dest\n"
                ZIP::create "$src" "$dest"
                if [ $? -ne 0 ]; then
                        OS::print_status error "packaging failed.\n"
                        return 1
                fi
                ;;
        *)
                dest="${dest}/${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.tar.xz"
                OS::print_status info "packaging $dest\n"
                TARXZ::create "$src" "$dest"
                if [ $? -ne 0 ]; then
                        OS::print_status error "packaging failed.\n"
                        return 1
                fi
                ;;
        esac


        # (5.3) report task verdict
        OS::print_status success "\n\n"
done
return 0

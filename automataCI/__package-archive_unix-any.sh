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
PACKAGE::run_archive() {
        src="archive_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}"
        src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${src}"
        dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
        OS::print_status info "archiving ${src} for ${TARGET_OS}-${TARGET_ARCH}\n"
        OS::print_status info "remaking workspace directory $src\n"
        FS::remake_directory "$src"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi

        # copy all complimentary files to the workspace
        if [ -z "$(type -t PACKAGE::assemble_archive_content)" ]; then
                OS::print_status error "missing PACKAGE::assemble_archive_content function.\n"
                return 1
        fi

        OS::print_status info "assembling package files...\n"
        PACKAGE::assemble_archive_content \
                "$i" \
                "$src" \
                "$TARGET_NAME" \
                "$TARGET_OS" \
                "$TARGET_ARCH"
        if [ $? -ne 0 ]; then
                OS::print_status error "assembling failed.\n"
                return 1
        fi

        # archive the assembled payload
        case "$TARGET_OS" in
        windows)
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

        # report status
        return 0
}

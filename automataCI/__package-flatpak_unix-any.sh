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
PACKAGE::run_flatpak() {
        FLATPAK::is_available "$TARGET_OS" "$TARGET_ARCH" && __ret=0 || __ret=1
        if [ $__ret -ne 0 ]; then
                OS::print_status warning "FLATPAK is incompatible or not available. Skipping.\n"
                return 0
        fi

        src="flatpak_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}"
        src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${src}"
        dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
        OS::print_status info "Creating FLATPAK package...\n"
        OS::print_status info "remaking workspace directory $src\n"
        FS::remake_directory "$src"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi

        TARGET_PATH="${dest}/flatpak_${TARGET_SKU}_${PROJECT_VERSION}_${TARGET_ARCH}"
        OS::print_status info "checking output file existence...\n"
        if [ -f "${TARGET_PATH}" ]; then
                OS::print_status error "check failed - output exists!\n"
                return 1
        fi

        # copy all complimentary files to the workspace
        OS::print_status info "assembling package files...\n"
        if [ -z "$(type -t PACKAGE::assemble_flatpak_content)" ]; then
                OS::print_status error "missing PACKAGE::assemble_flatpak_content function.\n"
                return 1
        fi
        PACKAGE::assemble_flatpak_content \
                "$i" \
                "$src" \
                "$TARGET_NAME" \
                "$TARGET_OS" \
                "$TARGET_ARCH"
        if [ $? -ne 0 ]; then
                OS::print_status error "assembly failed.\n"
                return 1
        fi

        # generate required files
        OS::print_status info "creating manifest file...\n"
        FLATPAK::create_manifest \
                "$src" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}" \
                "$PROJECT_APP_ID" \
                "$PROJECT_SKU" \
                "$TARGET_ARCH" \
                "$PROJECT_FLATPAK_RUNTIME" \
                "$PROJECT_FLATPAK_RUNTIME_VERSION" \
                "$PROJECT_FLATPAK_SDK"
        __ret=$?
        if [ $__ret -eq 2 ]; then
                OS::print_status info "manual injection detected.\n"
        elif [ $__ret -ne 0 ]; then
                OS::print_status error "create failed.\n"
                return 1
        fi

        OS::print_status info "creating app info XML file...\n"
        FLATPAK::create_appinfo \
                "$src" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}"
        __ret=$?
        if [ $__ret -eq 2 ]; then
                OS::print_status info "manual injection detected.\n"
        elif [ $__ret -ne 0 ]; then
                OS::print_status error "create failed.\n"
                return 1
        fi

        # archive the assembled payload
        OS::print_status info "archiving .flatpak package...\n"
        FLATPAK::create_archive \
                "$src" \
                "$TARGET_PATH" \
                "$PROJECT_APP_ID" \
                "$PROJECT_GPG_ID"
        if [ $? -ne 0 ]; then
                OS::print_status error "package failed.\n"
                return 1
        fi

        # report status
        return 0
}

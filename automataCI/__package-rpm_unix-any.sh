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
PACKAGE::run_rpm() {
        RPM::is_available "$TARGET_OS" "$TARGET_ARCH" && __ret=0 || __ret=1
        if [ $__ret -ne 0 ]; then
                OS::print_status warning "RPM is incompatible or not available. Skipping.\n"
                return 0
        fi

        src="rpm_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}"
        src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${src}"
        dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
        OS::print_status info "Creating RPM package...\n"
        OS::print_status info "remaking workspace directory $src\n"
        FS::remake_directory "$src"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi
        FS::make_directory "${src}/BUILD"
        FS::make_directory "${src}/SPECS"

        # copy all complimentary files to the workspace
        OS::print_status info "assembling package files...\n"
        if [ -z "$(type -t PACKAGE::assemble_rpm_content)" ]; then
                OS::print_status error "missing PACKAGE::assemble_rpm_content function.\n"
                return 1
        fi
        PACKAGE::assemble_rpm_content \
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
        OS::print_status info "creating copyright.gz file...\n"
        COPYRIGHT::create_rpm \
                "$src" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/licenses/deb-copyright" \
                "$TARGET_SKU" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE"
        __ret=$?
        if [ $__ret -eq 2 ]; then
                OS::print_status info "manual injection detected.\n"
        elif [ $__ret -eq 1 ]; then
                OS::print_status error "create failed.\n"
                return 1
        fi

        OS::print_status info "creating man pages file...\n"
        MANUAL::create_rpm_manpage \
                "$src" \
                "$TARGET_SKU" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE"
        __ret=$?
        if [ $__ret -eq 2 ]; then
                OS::print_status info "manual injection detected.\n"
        elif [ $__ret -eq 1 ]; then
                OS::print_status error "create failed.\n"
                return 1
        fi

        OS::print_status info "creating spec file...\n"
        RPM::create_spec \
                "$src" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}" \
                "$TARGET_SKU" \
                "$PROJECT_VERSION" \
                "$PROJECT_CADENCE" \
                "$PROJECT_PITCH" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE"
        __ret=$?
        if [ $__ret -eq 2 ]; then
                OS::print_status info "manual injection detected.\n"
        elif [ $__ret -eq 1 ]; then
                OS::print_status error "create failed.\n"
                return 1
        fi

        # archive the assembled payload
        OS::print_status info "archiving .rpm package...\n"
        RPM::create_archive \
                "$src" \
                "$dest" \
                "$PROJECT_SKU" \
                "$TARGET_ARCH"
        if [ $? -ne 0 ]; then
                OS::print_status error "package failed.\n"
                return 1
        fi

        # report status
        return 0
}

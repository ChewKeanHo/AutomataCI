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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/copyright.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/manual.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/deb.sh"




PACKAGE::run_deb() {
        _dest="$1"
        _target="$2"
        _target_filename="$3"
        _target_os="$4"
        _target_arch="$5"
        _changelog_deb="$6"

        OS::print_status info "checking deb functions availability...\n"
        DEB::is_available "$_target_os" "$_target_arch"
        case $? in
        2)
                OS::print_status warning "DEB is incompatible (OS type). Skipping.\n"
                return 0
                ;;
        3)
                OS::print_status warning "DEB is incompatible (CPU type). Skipping.\n"
                return 0
                ;;
        0)
                ;;
        *)
                OS::print_status warning "DEB is unavailable. Skipping.\n"
                return 0
                ;;
        esac

        OS::print_status info "checking manual docs functions availability...\n"
        MANUAL::is_available
        if [ $? -ne 0 ]; then
                OS::print_status warning "Man docs functions is unavailable. Skipping.\n"
                return 0
        fi

        # prepare workspace and required values
        _target_path="${PROJECT_SKU}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        FS::is_target_a_source "$_target"
        if [ $? -eq 0 ]; then
                _src="deb-src_${PROJECT_SKU}_${_target_os}-${_target_arch}"
                _target_path="${_dest}/src-${_target_path}.deb"
        else
                _src="deb_${PROJECT_SKU}_${_target_os}-${_target_arch}"
                _target_path="${_dest}/${_target_path}.deb"
        fi
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${_src}"
        OS::print_status info "Creating DEB package...\n"
        OS::print_status info "remaking workspace directory ${_src}\n"
        FS::remake_directory "${_src}"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi
        FS::make_directory "${_src}/control"
        FS::make_directory "${_src}/data"

        OS::print_status info "checking output file existence...\n"
        if [ -f "$_target_path" ]; then
                OS::print_status error "check failed - output exists!\n"
                return 1
        fi

        # copy all complimentary files to the workspace
        OS::print_status info "assembling package files...\n"
        OS::is_command_available "PACKAGE::assemble_deb_content"
        if [ $? -ne 0 ]; then
                OS::print_status error "missing PACKAGE::assemble_deb_content function.\n"
                return 1
        fi
        PACKAGE::assemble_deb_content \
                "$_target" \
                "$_src" \
                "$_target_filename" \
                "$_target_os" \
                "$_target_arch"
        case $? in
        10)
                FS::remove_silently "$_src"
                OS::print_status warning "packaging is not required. Skipping process.\n"
                return 0
                ;;
        0)
                ;;
        *)
                OS::print_status error "assembly failed.\n"
                return 1
                ;;
        esac

        # generate required files
        OS::print_status info "creating copyright.gz file...\n"
        COPYRIGHT::create_deb \
                "$_src" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/licenses/deb-copyright" \
                "$PROJECT_DEBIAN_IS_NATIVE" \
                "$PROJECT_SKU" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE"
        case $? in
        2)
                OS::print_status info "manual injection detected.\n"
                ;;
        0)
                ;;
        *)
                OS::print_status error "create failed.\n"
                return 1
                ;;
        esac

        OS::print_status info "creating changelog.gz file...\n"
        DEB::create_changelog \
                "$_src" \
                "$_changelog_deb" \
                "$PROJECT_DEBIAN_IS_NATIVE" \
                "$PROJECT_SKU"
        case $? in
        2)
                OS::print_status info "manual injection detected.\n"
                ;;
        0)
                ;;
        *)
                OS::print_status error "create failed.\n"
                return 1
                ;;
        esac

        OS::print_status info "creating man page files...\n"
        MANUAL::create_deb_manpage \
                "$_src" \
                "$PROJECT_DEBIAN_IS_NATIVE" \
                "$PROJECT_SKU" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE"
        case $? in
        2)
                OS::print_status info "manual injection detected.\n"
                ;;
        0)
                ;;
        *)
                OS::print_status error "create failed.\n"
                return 1
                ;;
        esac

        OS::print_status info "creating control/md5sums file...\n"
        DEB::create_checksum "$_src"
        case $? in
        2)
                OS::print_status info "manual injection detected.\n"
                ;;
        0)
                ;;
        *)
                OS::print_status error "create failed.\n"
                return 1
                ;;
        esac

        OS::print_status info "creating control/control file...\n"
        DEB::create_control \
                "$_src" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}" \
                "$PROJECT_SKU" \
                "$PROJECT_VERSION" \
                "$PROJECT_ARCH" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_PITCH" \
                "$PROJECT_DEBIAN_PRIORITY" \
                "$PROJECT_DEBIAN_SECTION"
        case $? in
        2)
                OS::print_status info "manual injection detected.\n"
                ;;
        0)
                ;;
        *)
                OS::print_status error "create failed.\n"
                return 1
                ;;
        esac

        # archive the assembled payload
        OS::print_status info "archiving .deb package...\n"
        DEB::create_archive "$_src" "$_target_path"
        if [ $? -ne 0 ]; then
                OS::print_status error "package failed.\n"
                return 1
        fi

        # report status
        return 0
}

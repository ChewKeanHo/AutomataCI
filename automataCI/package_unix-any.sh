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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/archive/tar.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/archive/zip.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/changelog.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/copyright.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/manual.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/deb.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/rpm.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/flatpak.sh"

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-archive_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-deb_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-rpm_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_package-flatpak_unix-any.sh"



# (1) safety checking control surfaces
OS::print_status info "checking tar functions availability...\n"
TAR::is_available
if [ $? -ne 0 ]; then
        OS::print_status error "check failed.\n"
        return 1
fi

OS::print_status info "checking zip functions availability...\n"
ZIP::is_available
if [ $? -ne 0 ]; then
        OS::print_status error "check failed.\n"
        return 1
fi

OS::print_status info "checking changelog functions availability...\n"
CHANGELOG::is_available
if [ $? -ne 0 ]; then
        OS::print_status error "checking failed.\n"
        return 1
fi

OS::print_status info "checking manual docs functions availability...\n"
MANUAL::is_available
if [ $? -ne 0 ]; then
        OS::print_status error "checking failed.\n"
        return 1
fi

OS::print_status info "sourcing content assembling functions from the project...\n"
recipe="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}"
recipe="${recipe}/package_unix-any.sh"
if [ ! -f "$recipe" ]; then
        OS::print_status error "sourcing failed - Missing file: ${recipe}\n"
        return 1
fi
. "$recipe"




# (2) clean up destination path
dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
OS::print_status info "remaking package directory: $dest\n"
FS::remake_directory "$dest"
if [ $? -ne 0 ]; then
        OS::print_status error "remake failed.\n"
        return 1
fi




# (3) validate changelog
OS::print_status info "validating ${PROJECT_VERSION} data changelog entry...\n"
CHANGELOG::compatible_data_version \
        "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/changelog" \
        "$PROJECT_VERSION"
if [ $? -ne 0 ]; then
        OS::print_status error "validation failed - there is an existing entry.\n"
        return 1
fi

OS::print_status info "validating ${PROJECT_VERSION} deb changelog entry...\n"
CHANGELOG::compatible_deb_version \
        "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/changelog" \
        "$PROJECT_VERSION"
if [ $? -ne 0 ]; then
        OS::print_status error "validation failed - there is an existing entry.\n"
        return 1
fi




# (4) assemble changelog
OS::print_status info "assembling markdown changelog...\n"
FILE_CHANGELOG_MD="${PROJECT_PATH_ROOT}/MARKDOWN.md"
CHANGELOG::assemble_md \
        "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/changelog" \
        "$FILE_CHANGELOG_MD" \
        "$PROJECT_VERSION"
if [ $? -ne 0 ]; then
        OS::print_status error "assembly failed.\n"
        return 1
fi

OS::print_status info "assembling deb changelog...\n"
FILE_CHANGELOG_DEB="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/deb/changelog"
mkdir -p "${FILE_CHANGELOG_DEB%/*}"
CHANGELOG::assemble_deb \
        "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/changelog" \
        "$FILE_CHANGELOG_DEB" \
        "$PROJECT_VERSION"
if [ $? -ne 0 ]; then
        OS::print_status error "assembly failed.\n"
        return 1
fi
FILE_CHANGELOG_DEB="${FILE_CHANGELOG_DEB}.gz"




# (5) begin packaging
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

        TARGET_SKU="$PROJECT_SKU"
        if [ ! "$TARGET_FILENAME" = "$TARGET_SKU" ]; then
                TARGET_SKU="${PROJECT_SKU}-src"
                if [ ! "$TARGET_FILENAME" = "$TARGET_SKU" ]; then
                        OS::print_status warning "incompatible file. Skipping.\n"
                        continue
                fi
        fi

        PACKAGE::run_archive
        if [ $? -ne 0 ]; then
                return 1
        fi

        PACKAGE::run_deb
        if [ $? -ne 0 ]; then
                return 1
        fi

        PACKAGE::run_rpm
        if [ $? -ne 0 ]; then
                return 1
        fi

        PACKAGE::run_flatpak
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report job verdict
        OS::print_status success "\n\n"
done
return 0

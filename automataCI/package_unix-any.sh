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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/archive/deb.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/changelog.sh"




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
        OS::print_status info "detected ${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${i}\n"


        # (5.1) parse build candidate
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


        # (5.2) archive into tar.xz / zip package
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

        # (5.2.1) copy necessary complimentary files to the package
        if [ -z "$(type -t PACKAGE::assemble_archive_content)" ]; then
                os::print_status error "missing PACKAGE::assemble_archive_content function.\n"
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

        # (5.2.2) archive the assembled payload
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


        # (5.3) archive debian .deb
        DEB::is_available "$TARGET_OS" "$TARGET_ARCH" && __ret=0 || __ret=1
        if [ $__ret -eq 0 ]; then
                src="deb_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}"
                src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${src}"
                dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
                OS::print_status info "Creating DEB package...\n"
                OS::print_status info "remaking workspace directory $src\n"
                FS::remake_directory "$src"
                mkdir -p "${src}/control" "${src}/data"
                if [ $? -ne 0 ]; then
                        OS::print_status error "remake failed.\n"
                        return 1
                fi

                TARGET_PATH="${dest}/${TARGET_SKU}_${PROJECT_VERSION}_${TARGET_ARCH}.deb"
                OS::print_status info "checking output file existence...\n"
                if [ -f "${TARGET_PATH}" ]; then
                        OS::print_status error "check failed - output exists!\n"
                        return 1
                fi

                # (5.3.1) copy necessary complimentary files to the package
                OS::print_status info "assembling package files...\n"
                if [ -z "$(type -t PACKAGE::assemble_deb_content)" ]; then
                        os::print_status error \
                                "missing PACKAGE::assemble_deb_content function.\n"
                        return 1
                fi
                PACKAGE::assemble_deb_content \
                        "$i" \
                        "$src" \
                        "$TARGET_NAME" \
                        "$TARGET_OS" \
                        "$TARGET_ARCH"
                if [ $? -ne 0 ]; then
                        OS::print_status error "assembly failed.\n"
                        return 1
                fi

                # (5.3.2) check and generate required files
                OS::print_status info "creating copyright.gz file...\n"
                DEB::create_copyright \
                        "$src" \
                        "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/licenses/deb-copyright" \
                        "$PROJECT_DEBIAN_IS_NATIVE" \
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

                OS::print_status info "creating changelog.gz file...\n"
                DEB::create_changelog \
                        "$src" \
                        "$FILE_CHANGELOG_DEB" \
                        "$PROJECT_DEBIAN_IS_NATIVE" \
                        "$TARGET_SKU"
                __ret=$?
                if [ $__ret -eq 2 ]; then
                        OS::print_status info "manual injection detected.\n"
                elif [ $__ret -eq 1 ]; then
                        OS::print_status error "create failed.\n"
                        return 1
                fi

                OS::print_status info "creating man pages file...\n"
                DEB::create_man_page \
                        "$src" \
                        "$PROJECT_DEBIAN_IS_NATIVE" \
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

                OS::print_status info "creating control/md5sums file...\n"
                DEB::create_checksum "$src"
                __ret=$?
                if [ $__ret -eq 2 ]; then
                        OS::print_status info "manual injection detected.\n"
                elif [ $__ret -eq 1 ]; then
                        OS::print_status error "create failed.\n"
                        return 1
                fi

                OS::print_status info "creating control/control file...\n"
                DEB::create_control \
                        "$src" \
                        "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/packages/deb" \
                        "$TARGET_SKU" \
                        "$PROJECT_VERSION" \
                        "$PROJECT_ARCH" \
                        "$PROJECT_CONTACT_NAME" \
                        "$PROJECT_CONTACT_EMAIL" \
                        "$PROJECT_CONTACT_WEBSITE" \
                        "$PROJECT_PITCH"
                __ret=$?
                if [ $__ret -eq 2 ]; then
                        OS::print_status info "manual injection detected.\n"
                elif [ $__ret -eq 1 ]; then
                        OS::print_status error "create failed.\n"
                        return 1
                fi

                # (5.3.2) archive the assembled payload
                OS::print_status info "archiving .deb package...\n"
                DEB::create_archive \
                        "$src" \
                        "$TARGET_PATH"
                if [ $? -ne 0 ]; then
                        OS::print_status error "package failed.\n"
                        return 1
                fi
        else
                OS::print_status warning "DEB is incompatible or not available. Skipping.\n"
        fi


        # (5.4) report task verdict
        OS::print_status success "\n\n"
done
return 0

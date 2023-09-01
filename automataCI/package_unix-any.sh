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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/flatpak.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/changelog.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/copyright.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/manual.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/deb.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/rpm.sh"

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/__package-deb_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/__package-rpm_unix-any.sh"



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

        PACKAGE::run_deb
        if [ $? -ne 0 ]; then
                return 1
        fi

        PACKAGE::run_rpm
        if [ $? -ne 0 ]; then
                return 1
        fi

        # (5.5) archive flatpak
        FLATPAK::is_available "$TARGET_OS" "$TARGET_ARCH" && __ret=0 || __ret=1
        if [ $__ret -eq 0 ]; then
                src="flatpak_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}"
                src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${src}"
                dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
                OS::print_status info "Creating FLATPAK package...\n"
                OS::print_status info "remaking workspace directory $src\n"
                FS::remake_directory "$src"
                mkdir -p "${src}"
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

                # (5.5.1) copy necessary complimentary files to the package
                OS::print_status info "assembling package files...\n"
                if [ -z "$(type -t PACKAGE::assemble_flatpak_content)" ]; then
                        OS::print_status error \
                                "missing PACKAGE::assemble_flatpak_content function.\n"
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

                # (5.5.2) check and generate required files
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

                # (5.5.3) create appinfo.xml
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

                # (5.5.4) archive the assembled payload
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
        else
                OS::print_status warning "FLATPAK is incompatible or not available. Skipping.\n"
        fi


        # (5.6) report task verdict
        OS::print_status success "\n\n"
done
return 0

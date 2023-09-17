#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/checksum/shasum.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/crypto/gpg.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/versioners/git.sh"

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-deb_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-rpm_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-docker_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-pypi_unix-any.sh"




# safety check control surfaces
OS::print_status info "Checking shasum availability...\n"
SHASUM::is_available
if [ $? -ne 0 ]; then
        OS::print_status error "Check failed.\n"
        return 1
fi




# setup release repo
OS::print_status info "Setup artifact release repo...\n"
__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}"
GIT::clone "${PROJECT_STATIC_REPO}" "${PROJECT_PATH_RELEASE}"
__exit=$?
cd "$__current_path" && unset __current_path
case $__exit in
2)
        OS::print_status info "Existing directory detected. Skipping...\n"
        ;;
0)
        ;;
*)
        OS::print_status error "Setup failed.\n"
        return 1
        ;;
esac




# source tech-specific functions
if [ ! -z "$PROJECT_PYTHON" ]; then
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/${PROJECT_PATH_CI}"
        __recipe="${__recipe}/release_unix-any.sh"
        OS::print_status info "Python technology detected. Parsing job recipe: ${__recipe}\n"

        FS::is_file "$__recipe"
        if [ $? -ne 0 ]; then
                OS::print_status error "Parse failed - missing file.\n"
                return 1
        fi

        . "$__recipe"
        if [ $? -ne 0 ]; then
                return 1
        fi
fi




# run pre-processors
if [ ! -z "$PROJECT_PYTHON" ]; then
        OS::print_status info "running python pre-processing function...\n"
        OS::is_command_available "RELEASE::run_python_pre_processor"
        if [ $? -ne 0 ]; then
                OS::print_status error "missing RELEASE::run_python_pre_processor function.\n"
                return 1
        fi

        RELEASE::run_python_pre_processor "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
        case $? in
        10)
                OS::print_status warning "release is not required. Skipping process.\n"
                return 0
                ;;
        0)
                ;;
        *)
                OS::print_status error "pre-processor failed.\n"
                return 1
                ;;
        esac
fi




# loop through each package and publish accordingly
for TARGET in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"/*; do
        OS::print_status info "processing ${TARGET}\n"

        RELEASE::run_deb \
                "$TARGET" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_rpm \
                "$TARGET" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_docker \
                "$TARGET" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_pypi \
                "$TARGET" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}"
        if [ $? -ne 0 ]; then
                return 1
        fi
done




# certify all payloads
__sha256_file="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/sha256.txt"
__sha256_target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/sha256.txt"
__sha512_file="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/sha512.txt"
__sha512_target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/sha512.txt"


FS::remove_silently "$__sha256_file"
FS::remove_silently "$__sha256_target"
FS::remove_silently "$__sha512_file"
FS::remove_silently "$__sha512_target"


GPG::is_available "$PROJECT_GPG_ID"
if [ $? -eq 0 ]; then
        for TARGET in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"/*; do
                if [ "${TARGET%%.asc*}" != "${TARGET}" ]; then
                        continue # it's a gpg cert
                fi

                OS::print_status info "gpg signing: ${TARGET}\n"
                FS::remove_silently "${TARGET}.asc"
                GPG::detach_sign_file "$TARGET" "$PROJECT_GPG_ID"
                if [ $? -ne 0 ]; then
                        OS::print_status error "sign failed\n"
                        return 1
                fi
        done

        OS::print_status info "exporting GPG public key...\n"
        __keyfile="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/${PROJECT_SKU}.gpg.asc"
        GPG::export_public_key "$__keyfile" "$PROJECT_GPG_ID"
        if [ $? -ne 0 ]; then
                OS::print_status error "export failed\n"
                return 1
        fi

        FS::copy_file \
                "$__keyfile" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${PROJECT_SKU}.gpg.asc"
        if [ $? -ne 0 ]; then
                OS::print_status error "export failed\n"
                return 1
        fi
fi


for TARGET in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"/*; do
        if [ ! -z "$PROJECT_RELEASE_SHA256" ]; then
                OS::print_status info "sha256 checksuming $TARGET\n"
                __value="$(SHASUM::create_file "$TARGET" "256")"
                if [ $? -ne 0 ]; then
                        OS::print_status error "sha256 failed.\n"
                        return 1
                fi

                FS::append_file "${__sha256_file}" "\
${__value}  ${TARGET##*/}
"
                if [ $? -ne 0 ]; then
                        OS::print_status error "sha256 failed.\n"
                        return 1
                fi
        fi


        if [ ! -z "$PROJECT_RELEASE_SHA512" ]; then
                OS::print_status info "sha512 checksuming $TARGET\n"
                __value="$(SHASUM::create_file "$TARGET" "512")"
                if [ $? -ne 0 ]; then
                        OS::print_status error "sha512 failed.\n"
                        return 1
                fi

                FS::append_file "${__sha512_file}" "\
${__value}  ${TARGET##*/}
"
                if [ $? -ne 0 ]; then
                        OS::print_status error "sha512 failed.\n"
                        return 1
                fi
        fi
done


if [ -f "${__sha256_file}" ]; then
        OS::print_status info "exporting sha256.txt...\n"
        FS::move "${__sha256_file}" "$__sha256_target"
        if [ $? -ne 0 ]; then
                OS::print_status error "export failed.\n"
                return 1
        fi
fi


if [ -f "${__sha512_file}" ]; then
        OS::print_status info "exporting sha512.txt...\n"
        FS::move "${__sha512_file}" "$__sha512_target"
        if [ $? -ne 0 ]; then
                OS::print_status error "export failed.\n"
                return 1
        fi
fi




# run post-processors
if [ ! -z "$PROJECT_PYTHON" ]; then
        OS::print_status info "running python post-processing function...\n"
        OS::is_command_available "RELEASE::run_python_post_processor"
        if [ $? -ne 0 ]; then
                OS::print_status error "missing RELEASE::run_python_post_processor function.\n"
                return 1
        fi

        RELEASE::run_python_post_processor \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
        case $? in
        0|10)
                ;;
        *)
                OS::print_status error "post-processor failed.\n"
                return 1
                ;;
        esac
fi




# report status
OS::print_status success "\n\n"
return 0

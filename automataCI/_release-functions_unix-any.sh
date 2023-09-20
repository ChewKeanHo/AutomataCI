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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/versioners/git.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/crypto/gpg.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/changelog.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/checksum/shasum.sh"




RELEASE::run_checksum_seal() {
        # execute
        __sha256_file="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/sha256.txt"
        __sha256_target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/sha256.txt"
        __sha512_file="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/sha512.txt"
        __sha512_target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/sha512.txt"


        FS::remove_silently "$__sha256_file"
        FS::remove_silently "$__sha256_target"
        FS::remove_silently "$__sha512_file"
        FS::remove_silently "$__sha512_target"


        # gpg sign all packages
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


        # shasum all files
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


        if [ -f "$__sha256_file" ]; then
                OS::print_status info "exporting sha256.txt...\n"
                FS::move "${__sha256_file}" "$__sha256_target"
                if [ $? -ne 0 ]; then
                        OS::print_status error "export failed.\n"
                        return 1
                fi
        fi


        if [ -f "$__sha512_file" ]; then
                OS::print_status info "exporting sha512.txt...\n"
                FS::move "${__sha512_file}" "$__sha512_target"
                if [ $? -ne 0 ]; then
                        OS::print_status error "export failed.\n"
                        return 1
                fi
        fi


        # report status
        return 0
}




RELEASE::initiate() {
        # safety check control surfaces
        OS::print_status info "Checking shasum availability...\n"
        SHASUM::is_available
        if [ $? -ne 0 ]; then
                OS::print_status error "Check failed.\n"
                return 1
        fi

        # execute
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}"
        __recipe="${__recipe}/release_unix-any.sh"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info \
                        "Baseline source detected. Parsing job recipe: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Parse failed.\n"
                        return 1
                fi
        fi


        if [ ! -z "$PROJECT_PYTHON" ]; then
                __recipe="${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/${PROJECT_PATH_CI}"
                __recipe="${__recipe}/release_unix-any.sh"
                FS::is_file "$__recipe"
                if [ $? -eq 0 ]; then
                        OS::print_status info \
                                "Python technology detected. Parsing job recipe: ${__recipe}\n"
                        . "$__recipe"
                        if [ $? -ne 0 ]; then
                                OS::print_status error "Parse failed.\n"
                                return 1
                        fi
                fi
        fi


        # report status
        return 0
}




RELEASE::run_changelog_conclude() {
        # execute
        OS::print_status info "Sealing changelog latest entries...\n"
        CHANGELOG::seal \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/changelog" \
                "$PROJECT_VERSION"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}




RELEASE::run_release_repo_conclude() {
        # validate input
        OS::print_status info "Sourcing commit id for tagging...\n"
        __tag="$(GIT::get_latest_commit_id)"
        if [ -z "$__tag" ]; then
                OS::print_status error "Source failed.\n"
                return 1
        fi

        # execute
        __current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"


        OS::print_status info "Generate required notice file...\n"
        FS::write_file "Home.md" "\
# ${PROJECT_NAME} Static Distribution Repository

This is a re-purposed repository for housing various distribution ecosystem
such as but not limited to \`.deb\`, \`.rpm\`, \`.flatpak\`, and etc for folks
to \`apt-get install\`, \`yum install\`, or \`flatpak install\`.
"


        OS::print_status info "Committing release repo...\n"
        GIT::autonomous_force_commit \
                "$__tag" \
                "$PROJECT_STATIC_REPO_KEY" \
                "$PROJECT_STATIC_REPO_BRANCH"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                OS::print_status error "Commit failed.\n"
                return 1
        fi

        cd "$__current_path" && unset __current_path

        # report status
        return 0
}




RELEASE::run_release_repo_setup() {
        # execute
        __current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"

        OS::print_status info "Hard resetting git to first commit...\n"
        GIT::hard_reset_to_init "$PROJECT_PATH_ROOT"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                OS::print_status error "Reset failed.\n"
                return 1
        fi

        cd "$__current_path" && unset __current_path


        # report status
        return 0
}

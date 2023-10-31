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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/strings.sh"




RUST::activate_local_environment() {
        # validate input
        RUST::is_localized
        if [ $? -eq 0 ] ; then
                return 0
        fi


        # execute
        __location="$(RUST::get_activator_path)"
        if [ ! -f "$__location" ]; then
                return 1
        fi

        . "$__location"
        RUST::is_localized
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




RUST::cargo_login() {
        # validate input
        if [ -z "$CARGO_REGISTRY" ] || [ -z "$CARGO_PASSWORD" ]; then
                return 1
        fi


        # execute
        cargo login --registry "$CARGO_REGISTRY" "$CARGO_PASSWORD"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




RUST::cargo_logout() {
        # execute
        cargo logout
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::remove_silently "~/.cargo/credentials.toml"


        # report status
        return 0
}




RUST::cargo_release_crate() {
        #__source_directory="$1"


        # validate input
        if [ -z "$1" ] || [ ! -d "$1" ]; then
                return 1
        fi


        # execute
        __current_path="$PWD" && cd "$1"
        cargo publish
        __exit_code=$?
        cd "$__current_path" && unset __current_path

        if [ $__exit_code -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




RUST::crate_is_valid() {
        #__target="$1"


        # validate input
        if [ -z "$1" ] || [ ! -d "$1" ]; then
                return 1
        fi


        # execute
        STRINGS::has_prefix "cargo" "${1##*/}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        __hasCARGO="false"
        for __file in "${1}/"*; do
                if [ ! -e "$__file" ]; then
                        continue
                fi

                if [ ! "${__file%%Cargo.toml*}" = "${__file}" ]; then
                        __hasCARGO="true"
                fi
        done

        if [ "$__hasCARGO" = "true" ]; then
                return 0
        fi


        # report status
        return 1
}




RUST::create_archive() {
        __source_directory="$1"
        __target_directory="$2"


        # validate input
        if [ -z "$__source_directory" ] ||
                [ -z "$__target_directory" ] ||
                [ ! -d "$__source_directory" ] ||
                [ ! -d "$__target_directory" ]; then
                return 1
        fi

        RUST::is_localized
        if [ $? -ne 0 ]; then
                RUST::activate_local_environment
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        # execute
        FS::remove_silently "${__source_directory}/Cargo.lock"

        __current_path="$PWD" && cd "$__source_directory"

        cargo build
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi

        cargo publish --dry-run
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi

        cd "$__current_path" && unset __current_path

        FS::remove_silently "${__source_directory}/target"
        FS::remake_directory "${__target_directory}"
        FS::copy_all "${__source_directory}/" "${__target_directory}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




RUST::create_cargo_toml() {
        __filepath="$1"
        __template="$2"
        __sku="$3"
        __version="$4"
        __pitch="$5"
        __edition="$6"
        __license="$7"
        __docs="$8"
        __website="$9"
        __repo="${10}"
        __readme="${11}"
        __contact_name="${12}"
        __contact_email="${13}"


        # validate input
        if [ -z "$__filepath" ] ||
                [ -z "$__template" ] ||
                [ ! -f "$__template" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__version" ] ||
                [ -z "$__pitch" ] ||
                [ -z "$__edition" ] ||
                [ -z "$__license" ] ||
                [ -z "$__docs" ] ||
                [ -z "$__website" ] ||
                [ -z "$__repo" ] ||
                [ -z "$__readme" ] ||
                [ -z "$__contact_name" ] ||
                [ -z "$__contact_email" ]; then
                return 1
        fi


        # execute
        FS::remove_silently "$__filepath"
        FS::write_file "$__filepath" "\
[package]
name = '$__sku'
version = '$__version'
description = '$__pitch'
edition = '$__edition'
license = '$__license'
documentation = '$__docs'
homepage = '$__website'
repository = '$__repo'
readme = '$__readme'
authors = [ '$__contact_name <$__contact_email>' ]




"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __begin_append=1
        __old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                if [ $__begin_append -ne 0 ] &&
                        [ ! "${__line%%\[AUTOMATACI BEGIN\]*}" = "${__line}" ]; then
                        __begin_append=0
                        continue
                fi

                if [ $__begin_append -ne 0 ]; then
                        continue
                fi

                FS::append_file "$__filepath" "$__line\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done < "$__template"
        IFS="$__old_IFS" && unset __old_IFS


        # update Cargo.lock
        RUST::is_localized
        if [ $? -ne 0 ]; then
                RUST::activate_local_environment
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        __current_path="$PWD" && cd "${__filepath%/*}"
        cargo update
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi

        cargo clean
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi
        cd "$__current_path" && unset __current_path


        # report status
        return 0
}




RUST::get_activator_path() {
        __location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_RUST_ENGINE}"
        __location="${__location}/activate.sh"
        printf -- "%b" "$__location"
}




RUST::get_build_target() {
        #__os="$1"
        #__arch="$2"


        # execute
        case "${1}-${2}" in
        aix-ppc64)
                __target='powerpc64-ibm-aix'
                ;;
        android-amd64)
                __target='x86_64-linux-android'
                ;;
        android-arm64)
                __target='aarch64-linux-android'
                ;;
        darwin-amd64)
                __target='x86_64-apple-darwin'
                ;;
        darwin-arm64)
                __target='aarch64-apple-darwin'
                ;;
        dragonfly-amd64)
                __target='x86_64-unknown-dragonfly'
                ;;
        freebsd-amd64)
                __target='x86_64-unknown-freebsd'
                ;;
        fuchsia-amd64)
                __target='x86_64-unknown-fuchsia'
                ;;
        fuchsia-arm64)
                __target='aarch64-unknown-fuchsia'
                ;;
        haiku-amd64)
                __target='x86_64-unknown-haiku'
                ;;
        illumos-amd64)
                __target='x86_64-unknown-illumos'
                ;;
        ios-amd64)
                __target='x86_64-apple-ios'
                ;;
        ios-arm64)
                __target='aarch64-apple-ios'
                ;;
        js-wasm)
                __target='wasm32-unknown-emscripten'
                ;;
        linux-armel|linux-armle)
                __target='arm-unknown-linux-musleabi'
                ;;
        linux-armhf)
                __target='arm-unknown-linux-musleabihf'
                ;;
        linux-armv7)
                __target='armv7-unknown-linux-musleabihf'
                ;;
        linux-amd64)
                __target='x86_64-unknown-linux-musl'
                ;;
        linux-arm64)
                __target='aarch64-unknown-linux-musl'
                ;;
        linux-loongarch64)
                __target='loongarch64-unknown-linux-gnu'
                ;;
        linux-mips)
                __target='mips-unknown-linux-musl'
                ;;
        linux-mipsle|linux-mipsel)
                __target='mipsel-unknown-linux-musl'
                ;;
        linux-mips64)
                __target='mips64-unknown-linux-muslabi64'
                ;;
        linux-mips64el|linux-mips64le)
                __target='mips64el-unknown-linux-muslabi64'
                ;;
        linux-ppc64)
                __target='powerpc64-unknown-linux-gnu'
                ;;
        linux-ppc64le)
                __target='powerpc64le-unknown-linux-gnu'
                ;;
        linux-riscv64)
                __target='riscv64gc-unknown-linux-gnu'
                ;;
        linux-s390x)
                __target='s390x-unknown-linux-gnu'
                ;;
        linux-sparc)
                __target='sparc-unknown-linux-gnu'
                ;;
        netbsd-amd64)
                __target='x86_64-unknown-netbsd'
                ;;
        netbsd-arm64)
                __target='aarch64-unknown-netbsd'
                ;;
        netbsd-riscv64)
                __target='riscv64gc-unknown-netbsd'
                ;;
        netbsd-sparc)
                __target='sparc64-unknown-netbsd'
                ;;
        openbsd-amd64)
                __target='x86_64-unknown-openbsd'
                ;;
        openbsd-arm64)
                __target='aarch64-unknown-openbsd'
                ;;
        openbsd-ppc64)
                __target='powerpc64-unknown-openbsd'
                ;;
        openbsd-riscv64)
                __target='riscv64gc-unknown-openbsd'
                ;;
        openbsd-sparc)
                __target='sparc64-unknown-openbsd'
                ;;
        redox-amd64)
                __target='x86_64-unknown-redox'
                ;;
        solaris-amd64)
                __target='x86_64-pc-solaris'
                ;;
        wasip1-wasm)
                __target='wasm32-wasi'
                ;;
        windows-amd64)
                __target='x86_64-pc-windows-gnu'
                ;;
        windows-arm64)
                __target='aarch64-pc-windows-msvc'
                ;;
        *)
                __target=''
                ;;
        esac
        printf -- "%b" "${__target}"


        # report status
        if [ ! -z "$__target" ]; then
                return 0
        fi

        return 1
}




RUST::is_available() {
        if [ -z "$(type -t rustup)" ]; then
                return 1
        fi

        if [ -z "$(type -t rustc)" ]; then
                return 1
        fi

        if [ -z "$(type -t cargo)" ]; then
                return 1
        fi

        return 0
}




RUST::is_localized() {
        if [ ! -z "$PROJECT_RUST_LOCALIZED" ] ; then
                return 0
        fi

        return 1
}




RUST::setup_local_environment() {
        # validate input
        if [ -z "$PROJECT_PATH_ROOT" ]; then
                return 1
        fi

        if [ -z "$PROJECT_PATH_TOOLS" ]; then
                return 1
        fi

        if [ -z "$PROJECT_PATH_AUTOMATA" ]; then
                return 1
        fi

        if [ -z "$PROJECT_PATH_RUST_ENGINE" ]; then
                return 1
        fi

        if [ -z "$PROJECT_OS" ]; then
                return 1
        fi

        if [ -z "$PROJECT_ARCH" ]; then
                return 1
        fi

        RUST::is_localized
        if [ $? -eq 0 ] ; then
                return 0
        fi


        # execute
        __label="($PROJECT_PATH_RUST_ENGINE)"
        __location="$(RUST::get_activator_path)"
        export CARGO_HOME="${__location%/*}"
        export RUSTUP_HOME="${__location%/*}"

        ## download installer from official portal
        sh "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/rust-rustup.sh" \
                -y \
                --no-modify-path

        ## it's a clean repo. Start setting up localized environment...
        FS::make_housing_directory "$__location"
        FS::write_file "${__location}" "\
#!/bin/sh
deactivate() {
        PATH=:\${PATH}:
        PATH=\${PATH//:\$CARGO_HOME/bin:/:}
        PATH=\${PATH%:}
        export PS1=\"\${PS1##*${__label} }\"
        unset PROJECT_RUST_LOCALIZED
        unset CARGO_HOME RUSTUP_HOME
        return 0
}

# activate
export CARGO_HOME='${CARGO_HOME}'
export RUSTUP_HOME='${RUSTUP_HOME}'
export PROJECT_RUST_LOCALIZED='${__location}'
export PATH=\$PATH:\${CARGO_HOME}/bin
export PS1=\"${__label} \${PS1}\"

if [ -z \"\$(type -t 'rustup')\" ] ||
        [ -z \"\$(type -t 'rustc')\" ] ||
        [ -z \"\$(type -t 'cargo')\" ]; then
        1>&2 printf -- '[ ERROR ] missing rust compiler.\\\\n'
        deactivate && unset deactivate
        return 1
fi

return 0
"
        if [ ! -f "${__location}" ]; then
                return 1
        fi


        # testing the activation
        RUST::activate_local_environment
        if [ $? -ne 0 ] ; then
                return 1
        fi


        # setup localized compiler
        rustup target add "$(RUST::get_build_target "$PROJECT_OS" "$PROJECT_ARCH")"
        if [ $? -ne 0 ]; then
                return 1
        fi

        rustup component add llvm-tools-preview
        if [ $? -ne 0 ]; then
                return 1
        fi

        cargo install grcov
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}

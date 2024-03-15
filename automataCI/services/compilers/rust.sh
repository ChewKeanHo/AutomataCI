#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"




RUST_Activate_Local_Environment() {
        # validate input
        RUST_Is_Localized
        if [ $? -eq 0 ] ; then
                return 0
        fi


        # execute
        ___location="$(RUST_Get_Activator_Path)"
        FS_Is_File "$___location"
        if [ $? -ne 0 ]; then
                return 1
        fi

        . "$___location"
        RUST_Is_Localized
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




RUST_Cargo_Login() {
        # validate input
        if [ $(STRINGS_Is_Empty "$CARGO_REGISTRY") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$CARGO_PASSWORD") -eq 0 ]; then
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




RUST_Cargo_Logout() {
        # execute
        cargo logout
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Remove_Silently "~/.cargo/credentials.toml"


        # report status
        return 0
}




RUST_Cargo_Release_Crate() {
        #___source_directory="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___current_path="$PWD" && cd "$1"
        cargo publish
        ___process=$?
        cd "$___current_path" && unset ___current_path

        if [ $___process -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




RUST_Crate_Is_Valid() {
        #___target="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        STRINGS_Has_Prefix "cargo" "${1##*/}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        ___hasCARGO="false"
        for ___file in "${1}/"*; do
                if [ ! -e "$___file" ]; then
                        continue
                fi

                if [ ! "${___file%%Cargo.toml*}" = "${___file}" ]; then
                        ___hasCARGO="true"
                fi
        done

        if [ "$___hasCARGO" = "true" ]; then
                return 0
        fi


        # report status
        return 1
}




RUST_Create_Archive() {
        ___source_directory="$1"
        ___target_directory="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$___source_directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target_directory") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___source_directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___target_directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RUST_Activate_Local_Environment
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        FS_Remove_Silently "${___source_directory}/Cargo.lock"

        ___current_path="$PWD" && cd "$___source_directory"

        cargo build
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi

        cargo publish --dry-run
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi

        cd "$___current_path" && unset ___current_path

        FS_Remove_Silently "${___source_directory}/target"
        FS_Remake_Directory "${___target_directory}"
        FS_Copy_All "${___source_directory}/" "${___target_directory}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




RUST_Create_CARGO_TOML() {
        ___filepath="$1"
        ___template="$2"
        ___sku="$3"
        ___version="$4"
        ___pitch="$5"
        ___edition="$6"
        ___license="$7"
        ___docs="$8"
        ___website="$9"
        ___repo="${10}"
        ___readme="${11}"
        ___contact_name="${12}"
        ___contact_email="${13}"


        # validate input
        if [ $(STRINGS_Is_Empty "$___filepath") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___template") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___sku") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___pitch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___edition") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___license") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___docs") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___website") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___repo") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___readme") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___contact_name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___contact_email") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$___template"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        FS_Remove_Silently "$___filepath"
        FS_Write_File "$___filepath" "\
[package]
name = '$___sku'
version = '$___version'
description = '$___pitch'
edition = '$___edition'
license = '$___license'
documentation = '$___docs'
homepage = '$___website'
repository = '$___repo'
readme = '$___readme'
authors = [ '$___contact_name <$___contact_email>' ]




"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ___begin_append=1
        ___old_IFS="$IFS"
        while IFS="" read -r ___line || [ -n "$___line" ]; do
                if [ $___begin_append -ne 0 ] &&
                        [ ! "${___line%%\[AUTOMATACI BEGIN\]*}" = "${___line}" ]; then
                        ___begin_append=0
                        continue
                fi

                if [ $___begin_append -ne 0 ]; then
                        continue
                fi

                FS_Append_File "$___filepath" "$___line\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done < "$___template"
        IFS="$___old_IFS" && unset ___old_IFS


        # update Cargo.lock
        RUST_Activate_Local_Environment
        if [ $? -ne 0 ]; then
                return 1
        fi

        ___current_path="$PWD" && cd "${___filepath%/*}"
        cargo update
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi

        cargo clean
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi
        cd "$___current_path" && unset ___current_path


        # report status
        return 0
}




RUST_Get_Activator_Path() {
        # execute
        ___location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_RUST_ENGINE}"
        ___location="${___location}/activate.sh"
        printf -- "%b" "$___location"
}




RUST_Get_Build_Target() {
        #___os="$1"
        #___arch="$2"


        # execute
        case "${1}-${2}" in
        aix-ppc64)
                ___target='powerpc64-ibm-aix'
                ;;
        android-amd64)
                ___target='x86_64-linux-android'
                ;;
        android-arm64)
                ___target='aarch64-linux-android'
                ;;
        darwin-amd64)
                ___target='x86_64-apple-darwin'
                ;;
        darwin-arm64)
                ___target='aarch64-apple-darwin'
                ;;
        dragonfly-amd64)
                ___target='x86_64-unknown-dragonfly'
                ;;
        freebsd-amd64)
                ___target='x86_64-unknown-freebsd'
                ;;
        fuchsia-amd64)
                ___target='x86_64-unknown-fuchsia'
                ;;
        fuchsia-arm64)
                ___target='aarch64-unknown-fuchsia'
                ;;
        haiku-amd64)
                ___target='x86_64-unknown-haiku'
                ;;
        illumos-amd64)
                ___target='x86_64-unknown-illumos'
                ;;
        ios-amd64)
                ___target='x86_64-apple-ios'
                ;;
        ios-arm64)
                ___target='aarch64-apple-ios'
                ;;
        js-wasm)
                ___target='wasm32-unknown-emscripten'
                ;;
        linux-armel|linux-armle)
                ___target='arm-unknown-linux-musleabi'
                ;;
        linux-armhf)
                ___target='arm-unknown-linux-musleabihf'
                ;;
        linux-armv7)
                ___target='armv7-unknown-linux-musleabihf'
                ;;
        linux-amd64)
                ___target='x86_64-unknown-linux-musl'
                ;;
        linux-arm64)
                ___target='aarch64-unknown-linux-musl'
                ;;
        linux-loongarch64)
                ___target='loongarch64-unknown-linux-gnu'
                ;;
        linux-mips)
                ___target='mips-unknown-linux-musl'
                ;;
        linux-mipsle|linux-mipsel)
                ___target='mipsel-unknown-linux-musl'
                ;;
        linux-mips64)
                ___target='mips64-unknown-linux-muslabi64'
                ;;
        linux-mips64el|linux-mips64le)
                ___target='mips64el-unknown-linux-muslabi64'
                ;;
        linux-ppc64)
                ___target='powerpc64-unknown-linux-gnu'
                ;;
        linux-ppc64le)
                ___target='powerpc64le-unknown-linux-gnu'
                ;;
        linux-riscv64)
                ___target='riscv64gc-unknown-linux-gnu'
                ;;
        linux-s390x)
                ___target='s390x-unknown-linux-gnu'
                ;;
        linux-sparc)
                ___target='sparc-unknown-linux-gnu'
                ;;
        netbsd-amd64)
                ___target='x86_64-unknown-netbsd'
                ;;
        netbsd-arm64)
                ___target='aarch64-unknown-netbsd'
                ;;
        netbsd-riscv64)
                ___target='riscv64gc-unknown-netbsd'
                ;;
        netbsd-sparc)
                ___target='sparc64-unknown-netbsd'
                ;;
        openbsd-amd64)
                ___target='x86_64-unknown-openbsd'
                ;;
        openbsd-arm64)
                ___target='aarch64-unknown-openbsd'
                ;;
        openbsd-ppc64)
                ___target='powerpc64-unknown-openbsd'
                ;;
        openbsd-riscv64)
                ___target='riscv64gc-unknown-openbsd'
                ;;
        openbsd-sparc)
                ___target='sparc64-unknown-openbsd'
                ;;
        redox-amd64)
                ___target='x86_64-unknown-redox'
                ;;
        solaris-amd64)
                ___target='x86_64-pc-solaris'
                ;;
        wasip1-wasm)
                ___target='wasm32-wasi'
                ;;
        windows-amd64)
                ___target='x86_64-pc-windows-gnu'
                ;;
        windows-arm64)
                ___target='aarch64-pc-windows-msvc'
                ;;
        *)
                ___target=''
                ;;
        esac
        printf -- "%b" "${___target}"
        if [ $(STRINGS_Is_Empty "$___target") -ne 0 ]; then
                return 0
        fi


        # report status
        return 1
}




RUST_Is_Available() {
        # execute
        OS_Is_Command_Available "rustup"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "rustc"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "cargo"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




RUST_Is_Localized() {
        # execute
        if [ $(STRINGS_Is_Empty "$PROJECT_RUST_LOCALIZED") -ne 0 ] ; then
                return 0
        fi


        # report status
        return 1
}




RUST_Setup_Local_Environment() {
        # validate input
        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_ROOT") -eq 0 ] ; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_TOOLS") -eq 0 ] ; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_AUTOMATA") -eq 0 ] ; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_RUST_ENGINE") -eq 0 ] ; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_OS") -eq 0 ] ; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_ARCH") -eq 0 ] ; then
                return 1
        fi

        RUST_Is_Localized
        if [ $? -eq 0 ] ; then
                return 0
        fi


        # execute
        ___label="($PROJECT_PATH_RUST_ENGINE)"
        ___location="$(RUST_Get_Activator_Path)"
        export CARGO_HOME="${___location%/*}"
        export RUSTUP_HOME="${___location%/*}"

        ## download installer from official portal
        sh "${LIBS_AUTOMATACI}/services/compilers/rust-rustup.sh" -y --no-modify-path

        ## it's a clean repo. Start setting up localized environment...
        FS_Make_Housing_Directory "$___location"
        FS_Write_File "${___location}" "\
#!/bin/sh
deactivate() {
        PATH=:\${PATH}:
        PATH=\${PATH//:\$CARGO_HOME/bin:/:}
        PATH=\${PATH%:}
        export PS1=\"\${PS1##*${___label} }\"
        unset PROJECT_RUST_LOCALIZED
        unset CARGO_HOME RUSTUP_HOME
        return 0
}


# check existing
if [ ! -z \"\$PROJECT_RUST_LOCALIZED\" ]; then
        return 0
fi


# activate
export CARGO_HOME='${CARGO_HOME}'
export RUSTUP_HOME='${RUSTUP_HOME}'
export PROJECT_RUST_LOCALIZED='${___location}'
export PATH=\$PATH:\${CARGO_HOME}/bin
export PS1=\"${___label} \${PS1}\"

if [ -z \"\$(type -t 'rustup')\" ] ||
        [ -z \"\$(type -t 'rustc')\" ] ||
        [ -z \"\$(type -t 'cargo')\" ]; then
        1>&2 printf -- '[ ERROR ] missing rust compiler.\\\\n'
        deactivate && unset deactivate
        return 1
fi

return 0
"
        FS_Is_File "$___location"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # testing the activation
        RUST_Activate_Local_Environment
        if [ $? -ne 0 ] ; then
                return 1
        fi


        # setup localized compiler
        rustup target add "$(RUST_Get_Build_Target "$PROJECT_OS" "$PROJECT_ARCH")"
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

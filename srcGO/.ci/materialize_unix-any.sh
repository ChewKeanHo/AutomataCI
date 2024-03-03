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




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/go.sh"




# safety checking control surfaces
OS::print_status info "checking go availability...\n"
GO::is_available
if [ $? -ne 0 ]; then
        OS::print_status error "missing go compiler.\n"
        return 1
fi


OS::print_status info "activating local environment...\n"
GO::activate_local_environment
if [ $? -ne 0 ]; then
        OS::print_status error "activation failed.\n"
        return 1
fi




# build output binary file
OS::print_status info "configuring build settings...\n"
__output_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
__arguments=""
__os="$PROJECT_OS"
__arch="$PROJECT_ARCH"
case "${__os}/${__arch}" in
aix/ppc64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
android/amd64)
        if [ "$PROJECT_OS" = "darwin" ]; then
                return 1
        fi

        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        __arguments="-buildmode=pie"
        ;;
android/arm64)
        if [ "$PROJECT_OS" = "darwin" ]; then
                return 1
        fi

        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        __arguments="-buildmode=pie"
        ;;
darwin/amd64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        __arguments="-buildmode=pie"
        ;;
darwin/arm64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        __arguments="-buildmode=pie"
        ;;
dragonfly/amd64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
freebsd/amd64)
        if [ "$PROJECT_OS" = "darwin" ]; then
                return 1
        fi

        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        __arguments="-buildmode=pie"
        ;;
illumos/amd64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
ios/amd64)
        if [ ! "$PROJECT_OS" = "darwin" ]; then
                return 1
        fi

        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
ios/arm64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        return 1 # impossible without cgo
        ;;
js/wasm)
        __filename="${__output_directory}/${PROJECT_SKU}_${__os}-${__arch}.js"
        FS_Remove_Silently "$__filename"
        FS_Copy_File "$(go env GOROOT)/misc/wasm/wasm_exec.js" "$__filename"
        if [ $? -ne 0 ]; then
                return 1
        fi

        __filename="${PROJECT_SKU}_${__os}-${__arch}.wasm"
        ;;
linux/amd64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        __arguments="-buildmode=pie"
        ;;
linux/arm64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        __arguments="-buildmode=pie"
        ;;
linux/ppc64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
linux/ppc64le)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        __arguments="-buildmode=pie"
        ;;
linux/riscv64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
linux/s390x)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
netbsd/amd64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
netbsd/arm64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
openbsd/amd64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
openbsd/arm64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
plan9/amd64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
solaris/amd64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        ;;
wasip1/wasm)
        __filename="${PROJECT_SKU}_${__os}-${__arch}.wasi"
        ;;
windows/amd64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}.exe"
        __arguments="-buildmode=pie"
        ;;
windows/arm64)
        __filename="${PROJECT_SKU}_${__os}-${__arch}.exe"
        __arguments="-buildmode=pie"
        ;;
*)
        return 1
        ;;
esac




# building target
OS::print_status info "building ${__filename}...\n"
FS_Remove_Silently "${__output_directory}/${__filename}"
CGO_ENABLED=0 GOOS="$__os" GOARCH="$__arch" go build \
        -C "${PROJECT_PATH_ROOT}/${PROJECT_GO}" \
        $__arguments \
        -ldflags "-s -w" \
        -trimpath \
        -gcflags "-trimpath=${GOPATH}" \
        -asmflags "-trimpath=${GOPATH}" \
        -o "${__output_directory}/${__filename}"
if [ $? -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi




# shipping executable
__source="${__output_directory}/${__filename}"
__dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BIN}/${PROJECT_SKU}"
OS::print_status info "exporting ${__source} to ${__dest}\n"
FS_Make_Housing_Directory "$__dest"
FS_Remove_Silently "$__dest"
FS_Move "$__source" "$__dest"
if [ $? -ne 0 ]; then
        OS::print_status error "export failed.\n"
        return 1
fi




# report status
return 0

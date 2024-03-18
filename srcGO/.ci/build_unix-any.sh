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




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/go.sh"




# execute
I18N_Activate_Environment
GO_Activate_Local_Environment
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi


__placeholders="\
${PROJECT_SKU}-src_any-any
${PROJECT_SKU}-homebrew_any-any
${PROJECT_SKU}-chocolatey_any-any
${PROJECT_SKU}-msi_any-any
"


__output_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
for __platform in $(go tool dist list); do
        # select supported platforms
        __os="${__platform%%/*}"
        __arch="${__platform##*/}"
        case "${__os}-${__arch}" in
        android-amd64)
                continue # impossible without cgo
                ;;
        android-386)
                continue # impossible without cgo
                ;;
        android-arm)
                continue # impossible without cgo
                ;;
        android-arm64)
                if [ "$PROJECT_OS" = "darwin" ]; then
                        continue
                fi
                ;;
        freebsd-amd64)
                if [ "$PROJECT_OS" = "darwin" ]; then
                        continue
                fi
                ;;
        ios-amd64)
                if [ ! "$PROJECT_OS" = "darwin" ]; then
                        continue
                fi
                ;;
        ios-arm64)
                continue # impossible without cgo
                ;;
        js-wasm)
                __filename="${__output_directory}/${PROJECT_SKU}_${__os}-${__arch}.js"
                FS_Remove_Silently "$__filename"
                FS_Copy_File "$(go env GOROOT)/misc/wasm/wasm_exec.js" "$__filename"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                ;;
        *)
                # proceed
                ;;
        esac
        __arguments="$(GO_Get_Compiler_Optimization_Arguments "$__os" "$__arch")"
        __filename="$(GO_Get_Filename "$PROJECT_SKU" "$__os" "$__arch")"

        I18N_Build "$__filename"
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
                I18N_Build_Failed
                return 1
        fi
done




# placeholding flag files
old_IFS="$IFS"
while IFS="" read -r __line || [ -n "$__line" ]; do
        if [ $(STRINGS_Is_Empty "$__line") -eq 0 ]; then
                continue
        fi


        # build the file
        __file="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__line}"
        I18N_Build "$__line"
        FS_Remove_Silently "$__file"
        FS_Touch_File "$__file"
        if [ $? -ne 0 ]; then
                I18N_Build_Failed
                return 1
        fi
done <<EOF
$__placeholders
EOF




# report status
return 0

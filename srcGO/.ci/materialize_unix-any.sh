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


I18N_Configure_Build_Settings
__output_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
__arguments="$(GO_Get_Compiler_Optimization_Arguments "$PROJECT_OS" "$PROJECT_ARCH")"

__filename="$(GO_Get_Filename "$PROJECT_SKU" "$PROJECT_OS" "$PROJECT_ARCH")"
if [ $(STRINGS_Is_Empty "$__filename") -eq 0 ]; then
        I18N_Configure_Failed
        return 1
fi


I18N_Build "$__filename"
FS_Remove_Silently "${__output_directory}/${__filename}"
CGO_ENABLED=0 GOOS="$PROJECT_OS" GOARCH="$PROJECT_ARCH" go build \
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


___source="${__output_directory}/${__filename}"
___dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BIN}/${PROJECT_SKU}"
I18N_Export "$___source" "$___dest"
FS_Make_Housing_Directory "$___dest"
FS_Remove_Silently "$___dest"
FS_Move "$___source" "$___dest"
if [ $? -ne 0 ]; then
        I18N_Export_Failed
        return 1
fi




# report status
return 0

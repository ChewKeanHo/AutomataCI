#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/c.sh"




# execute
FS_Remove_Silently "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BIN}"
FS_Remove_Silently "${PROJECT_PATH_ROOT}/${PROJECT_PATH_LIB}"

__arguments="$(C_Get_Strict_Settings)"
case "$PROJECT_OS" in
darwin)
        __arguments="${__arguments} -fPIC"
        ;;
*)
        __arguments="${__arguments} -pie -fPIE"
        ;;
esac

__compiler="$(C_Get_Compiler "$PROJECT_OS" "$PROJECT_ARCH")"
if [ $(STRINGS_Is_Empty "$__compiler") -eq 0 ]; then
        I18N_Build_Failed
        return 1
fi




# build main exectuable
I18N_Configure_Build_Settings
__target="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
__output="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
__workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/build-${__target}"
__log="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/build-${__target}"
__main="${PROJECT_PATH_ROOT}/${PROJECT_C}/executable.txt"
case "$PROJECT_OS" in
windows)
        __target="${__workspace}/${__target}.exe"
        ;;
*)
        __target="${__workspace}/${__target}.elf"
        ;;
esac

I18N_Build "$__main"
FS_Make_Directory "$__output"
FS_Remove_Silently "$__target"
C_Build "$__target" \
        "$__main" \
        "executable" \
        "$PROJECT_OS" \
        "$PROJECT_ARCH" \
        "$__workspace" \
        "$__log" \
        "$__compiler" \
        "$__arguments"
if [ $? -ne 0 ]; then
        I18N_Build_Failed
        return 1
fi

__dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BIN}/${PROJECT_SKU}"
if [ "$PROJECT_OS" = "windows" ]; then
        __dest="${__dest}.exe"
fi
I18N_Export "$__target" "$__dest"
FS_Make_Housing_Directory "$__dest"
FS_Remove_Silently "$__dest"
FS_Move "$__target" "$__dest"
if [ $? -ne 0 ]; then
        I18N_Export_Failed
        return 1
fi




# build main library
I18N_Configure_Build_Settings
__target="lib${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
__output="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
__workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/build-${__target}"
__log="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/build-${__target}"
__main="${PROJECT_PATH_ROOT}/${PROJECT_C}/library.txt"
case "$PROJECT_OS" in
windows)
        __target="${__workspace}/${__target}.dll"
        ;;
*)
        __target="${__workspace}/${__target}.a"
        ;;
esac

I18N_Build "$__main"
FS_Make_Directory "$__output"
FS_Remove_Silently "$__target"
C_Build "$__target" \
        "$__main" \
        "library" \
        "$PROJECT_OS" \
        "$PROJECT_ARCH" \
        "$__workspace" \
        "$__log" \
        "$__compiler" \
        "$__arguments"
if [ $? -ne 0 ]; then
        I18N_Build_Failed
        return 1
fi

__dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LIB}/lib${PROJECT_SKU}"
if [ "$PROJECT_OS" = "windows" ]; then
        __dest="${__dest}.dll"
else
        __dest="${__dest}.a"
fi
I18N_Export "$__target" "$__dest"
FS_Make_Housing_Directory "$__dest"
FS_Remove_Silently "$__dest"
FS_Move "$__target" "$__dest"
if [ $? -ne 0 ]; then
        I18N_Export_Failed
        return 1
fi




# report status
return 0

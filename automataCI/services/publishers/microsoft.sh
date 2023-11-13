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




MICROSOFT_Arch_Get() {
        # execute
        case "$1" in
        alpha)
                __value="Alpha"
                ;;
        amd64)
                __value="x64"
                ;;
        arm)
                __value="ARM"
                ;;
        arm64)
                __value="ARM64"
                ;;
        i386)
                __value="x86"
                ;;
        ia64)
                __value="ia64"
                ;;
        mips)
                __value="MIPs"
                ;;
        powerpc)
                __value="PowerPC"
                ;;
        *)
                __value=""
                ;;
        esac
        printf -- "%s" "$__value"


        # report status
        return 0
}




MICROSOFT_Arch_Interpret() {
        # execute
        case "$1" in
        Alpha)
                __value="alpha"
                ;;
        ARM)
                __value="arm"
                ;;
        ARM64)
                __value="arm64"
                ;;
        ia64)
                __value="ia64"
                ;;
        MIPs)
                __value="mips"
                ;;
        PowerPC)
                __value="powerpc"
                ;;
        x86)
                __value="i386"
                ;;
        x64)
                __value="amd64"
                ;;
        *)
                __value=""
                ;;
        esac
        printf -- "%s" "$__value"


        # report status
        return 0
}




MICROSOFT_Is_Available_Software() {
        return 1 # not applicable
}




MICROSOFT_Is_Available_UIXAML() {
        return 1 # not applicable
}




MICROSOFT_Is_Available_VCLibs() {
        return 1 # not applicable
}




MICROSOFT_Setup_UIXAML() {
        return 1 # not applicable
}




MICROSOFT_Setup_VCLibs() {
        return 1 # not applicable
}




MICROSOFT_Setup_WINGET() {
        return 1 # not applicable
}

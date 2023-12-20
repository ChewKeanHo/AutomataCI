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
MICROSOFT_Arch_Get() {
        # execute
        case "$1" in
        alpha)
                ___value="Alpha"
                ;;
        amd64)
                ___value="x64"
                ;;
        arm)
                ___value="ARM"
                ;;
        arm64)
                ___value="ARM64"
                ;;
        i386)
                ___value="x86"
                ;;
        ia64)
                ___value="ia64"
                ;;
        mips)
                ___value="MIPs"
                ;;
        powerpc)
                ___value="PowerPC"
                ;;
        *)
                ___value=""
                ;;
        esac
        printf -- "%s" "$___value"


        # report status
        return 0
}




MICROSOFT_Arch_Interpret() {
        # execute
        case "$1" in
        Alpha)
                ___value="alpha"
                ;;
        ARM)
                ___value="arm"
                ;;
        ARM64)
                ___value="arm64"
                ;;
        ia64)
                ___value="ia64"
                ;;
        MIPs)
                ___value="mips"
                ;;
        PowerPC)
                ___value="powerpc"
                ;;
        x86)
                ___value="i386"
                ;;
        x64)
                ___value="amd64"
                ;;
        *)
                ___value=""
                ;;
        esac
        printf -- "%s" "$___value"


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

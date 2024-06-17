#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
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
UNIX_Get_Arch() {
        # execute
        case "$1" in
        any)
                ___value="all"
                ;;
        386|i386|486|i486|586|i586|686|i686)
                ___value="i386"
                ;;
        armle)
                ___value="armel"
                ;;
        mipsle)
                ___value="mipsel"
                ;;
        mipsr6le)
                ___value="mipsr6el"
                ;;
        mipsn32le)
                ___value="mipsn32el"
                ;;
        mipsn32r6le)
                ___value="mipsn32r6el"
                ;;
        mips64le)
                ___value="mips64el"
                ;;
        mips64r6le)
                ___value="mips64r6el"
                ;;
        powerpcle)
                ___value="powerpcel"
                ;;
        ppc64le)
                ___value="ppc64el"
                ;;
        *)
                ___value="$1"
                ;;
        esac
        printf -- "%s" "$___value"


        # report status
        return 0
}

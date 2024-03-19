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
. "${LIBS_AUTOMATACI}/services/compilers/c.sh"




# execute
___source="${PROJECT_PATH_ROOT}/${PROJECT_C}"
I18N_Prepare "$___source"
___arguments="$(C_Get_Strict_Settings)"
case "$PROJECT_OS" in
darwin)
        ___arguments="${___arguments} -fPIC"
        ;;
*)
        ___arguments="${___arguments} -pie -fPIE"
        ;;
esac


I18N_Run_Test
C_Test "$___source" "$PROJECT_OS" "$PROJECT_ARCH" "$___arguments"
case "$?" in
0|10)
        # accepted
        ;;
*)
        I18N_Run_Failed
        return 1
        ;;
esac




# return status
return 0

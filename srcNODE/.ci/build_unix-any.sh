#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
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
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/compilers/node.sh"




# define build variables
__workspace_path="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/build-${PROJECT_SKU}_js-js"
__placeholders="\
"




# execute
I18N_Activate_Environment
NODE_Activate_Local_Environment
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi


## build the artifacts and move it to the workspace
I18N_Build "$PROJECT_NODE"
FS_Remove_Silently "$__workspace_path"
FS_Make_Housing_Directory "$__workspace_path"

__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_NODE}"
NODE_NPM_Run "build"
___process=$?
cd "$__current_path" && unset __current_path
if [ $___process -ne 0 ]; then
        I18N_Build_Failed
        return 1
fi

___source="${PROJECT_PATH_ROOT}/${PROJECT_NODE}/dist/build"
FS_Move "$___source" "$__workspace_path"
if [ $? -ne 0 ]; then
        I18N_Build_Failed
        return 1
fi

___dest="${__workspace_path}/package.json"
___old_IFS="$IFS"
while IFS="" read -r ___line || [ -n "$___line" ]; do
        ## overrides name
        ___key='  "name": '
        if [ $(STRINGS_Is_Empty "${___line%%${___key}*}") -eq 0 ]; then
                ___value="$(STRINGS_To_Lowercase "@${PROJECT_SCOPE}/${PROJECT_SKU}")"
                FS_Append_File "$___dest" "${___key}\"${___value}\",\n"
                if [ $? -ne 0 ]; then
                        IFS="$___old_IFS" && unset ___old_IFS
                        I18N_Build_Failed
                        return 1
                fi

                continue
        fi

        ## overrides version
        ___key='  "version": '
        if [ $(STRINGS_Is_Empty "${___line%%${___key}*}") -eq 0 ]; then
                FS_Append_File "$___dest" "${___key}\"${PROJECT_VERSION}\",\n"
                if [ $? -ne 0 ]; then
                        IFS="$___old_IFS" && unset ___old_IFS
                        I18N_Build_Failed
                        return 1
                fi

                continue
        fi

        ## overrides description
        ___key='  "description": '
        if [ $(STRINGS_Is_Empty "${___line%%${___key}*}") -eq 0 ]; then
                FS_Append_File "$___dest" "${___key}\"${PROJECT_PITCH}\",\n"
                if [ $? -ne 0 ]; then
                        IFS="$___old_IFS" && unset ___old_IFS
                        I18N_Build_Failed
                        return 1
                fi

                continue
        fi

        ## overrides author
        ___key='  "author": '
        if [ $(STRINGS_Is_Empty "${___line%%${___key}*}") -eq 0 ]; then
                FS_Append_File "$___dest" "${___key}\"${PROJECT_CONTACT_NAME}\",\n"
                if [ $? -ne 0 ]; then
                        IFS="$___old_IFS" && unset ___old_IFS
                        I18N_Build_Failed
                        return 1
                fi

                continue
        fi

        ## overrides license
        ___key='  "license": '
        if [ $(STRINGS_Is_Empty "${___line%%${___key}*}") -eq 0 ]; then
                FS_Append_File "$___dest" "${___key}\"${PROJECT_LICENSE}\",\n"
                if [ $? -ne 0 ]; then
                        IFS="$___old_IFS" && unset ___old_IFS
                        I18N_Build_Failed
                        return 1
                fi

                continue
        fi

        ## overrides homepage
        ___key='  "homepage": '
        if [ $(STRINGS_Is_Empty "${___line%%${___key}*}") -eq 0 ]; then
                FS_Append_File "$___dest" "${___key}\"${PROJECT_CONTACT_WEBSITE}\",\n"
                if [ $? -ne 0 ]; then
                        IFS="$___old_IFS" && unset ___old_IFS
                        I18N_Build_Failed
                        return 1
                fi

                continue
        fi

        ## retain
        FS_Append_File "$___dest" "${___line}\n"
        if [ $? -ne 0 ]; then
                IFS="$___old_IFS" && unset ___old_IFS
                I18N_Build_Failed
                return 1
        fi
done < "${PROJECT_PATH_ROOT}/${PROJECT_NODE}/package.json"
IFS="$___old_IFS" && unset ___old_IFS

## assemble other assets and npm metadata files
I18N_Assemble_Package
FS_Copy_File "${PROJECT_PATH_ROOT}/${PROJECT_README}" "${__workspace_path}/README.md"
if [ $? -ne 0 ]; then
        I18N_Assemble_Failed
        return 1
fi

FS_Copy_File "${PROJECT_PATH_ROOT}/${PROJECT_LICENSE_FILE}" "${__workspace_path}/LICENSE.txt"
if [ $? -ne 0 ]; then
        I18N_Assemble_Failed
        return 1
fi

## export npm tarball
### IMPORTANT: npm only recognizes .tgz file extension so rename it accordingly.
###            Also, keep the lib- prefix -NPM for CI identification purposes.
___dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/lib${PROJECT_SKU}-NPM_js-js.tgz"
I18N_Export "$___dest"
FS_Make_Housing_Directory "$___dest"
FS_Remove_Silently "$___dest"

__current_path="$PWD" && cd "$__workspace_path"
TAR_Create_GZ "$___dest" "."
___process=$?
cd "$__current_path" && unset __current_path
if [ $___process -ne 0 ]; then
        I18N_Export_Failed
        return 1
fi




# placeholding flag files
__old_IFS="$IFS"
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
                IFS="$__old_IFS" && unset __old_IFS
                return 1
        fi
done <<EOF
$__placeholders
EOF
IFS="$__old_IFS" && unset __old_IFS




# compose documentations




# report status
return 0

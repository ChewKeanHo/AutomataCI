#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#               http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/io/net/http.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/docker.sh"
. "${LIBS_AUTOMATACI}/services/compilers/installer.sh"
. "${LIBS_AUTOMATACI}/services/compilers/go.sh"
. "${LIBS_AUTOMATACI}/services/compilers/msi.sh"
. "${LIBS_AUTOMATACI}/services/compilers/python.sh"
. "${LIBS_AUTOMATACI}/services/crypto/notary.sh"
. "${LIBS_AUTOMATACI}/services/publishers/dotnet.sh"
. "${LIBS_AUTOMATACI}/services/publishers/homebrew.sh"
. "${LIBS_AUTOMATACI}/services/publishers/reprepro.sh"




# begin service
I18N_Install "brew"
HOMEBREW_Setup
if [ $? -ne 0 ]; then
        I18N_Install_Failed
        return 1
fi


I18N_Install "curl"
HTTP_Setup
if [ $? -ne 0 ]; then
        I18N_Install_Failed
        return 1
fi


I18N_Install "msitools"
MSI_Setup
if [ $? -ne 0 ]; then
        I18N_Install_Failed
        return 1
fi


I18N_Install "docker"
DOCKER_Setup
if [ $? -ne 0 ]; then
        I18N_Install_Failed
        return 1
fi


I18N_Install "reprepro"
REPREPRO_Setup
if [ $? -ne 0 ]; then
        I18N_Install_Failed
        return 1
fi


I18N_Install "osslsigncode"
NOTARY_Setup_Microsoft
if [ $? -ne 0 ]; then
        I18N_Install_Failed
        return 1
fi


if [ $(STRINGS_Is_Empty "$PROJECT_PYTHON") -ne 0 ]; then
        I18N_Install "python"
        PYTHON_Setup
        if [ $? -ne 0 ]; then
                I18N_Install_Failed
                return 1
        fi
fi


if [ $(STRINGS_Is_Empty "$PROJECT_GO") -ne 0 ]; then
        I18N_Install "go"
        GO_Setup
        if [ $? -ne 0 ]; then
                I18N_Install_Failed
                return 1
        fi
fi


if [ $(STRINGS_Is_Empty "$PROJECT_C") -ne 0 ] ||
        [ $(STRINGS_Is_Empty "$PROJECT_NIM") -ne 0 ] ||
        [ $(STRINGS_Is_Empty "$PROJECT_RUST") -ne 0 ]; then
        I18N_Install "c"
        INSTALLER::setup_c "$PROJECT_OS" "$PROJECT_ARCH"
        if [ $? -ne 0 ]; then
                I18N_Install_Failed
                return 1
        fi
fi


if [ $(STRINGS_Is_Empty "$PROJECT_DOTNET") -ne 0 ]; then
        I18N_Install "dotnet"
        DOTNET_Setup
        if [ $? -ne 0 ]; then
                I18N_Install_Failed
                return 1
        fi
fi


if [ $(STRINGS_Is_Empty "$PROJECT_NIM") -ne 0 ]; then
        I18N_Install "nim"
        INSTALLER::setup_nim "$PROJECT_OS" "$PROJECT_ARCH"
        if [ $? -ne 0 ]; then
                I18N_Install_Failed
                return 1
        fi
fi


if [ $(STRINGS_Is_Empty "$PROJECT_ANGULAR") -ne 0 ]; then
        I18N_Install "angular"
        INSTALLER::setup_angular "$PROJECT_OS" "$PROJECT_ARCH"
        if [ $? -ne 0 ]; then
                I18N_Install_Failed
                return 1
        fi
fi




# report status
I18N_Run_Successful
return 0

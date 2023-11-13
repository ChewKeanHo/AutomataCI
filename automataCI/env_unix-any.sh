#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/net/http.sh"
. "${LIBS_AUTOMATACI}/services/compilers/installer.sh"
. "${LIBS_AUTOMATACI}/services/compilers/msi.sh"
. "${LIBS_AUTOMATACI}/services/publishers/dotnet.sh"
. "${LIBS_AUTOMATACI}/services/publishers/homebrew.sh"

. "${LIBS_AUTOMATACI}/services/i18n/status-job-env.sh"
. "${LIBS_AUTOMATACI}/services/i18n/status-run.sh"




# begin service
I18N_Status_Print_Env_Install "brew"
HOMEBREW::setup
if [ $? -ne 0 ]; then
        I18N_Status_Print_Env_Install_Failed
        return 1
fi


I18N_Status_Print_Env_Install "curl"
HTTP_Setup
if [ $? -ne 0 ]; then
        I18N_Status_Print_Env_Install_Failed
        return 1
fi


I18N_Status_Print_Env_Install "msitools"
MSI_Setup
if [ $? -ne 0 ]; then
        I18N_Status_Print_Env_Install_Failed
        return 1
fi


I18N_Status_Print_Env_Install "docker"
INSTALLER::setup_docker
if [ $? -ne 0 ]; then
        I18N_Status_Print_Env_Install_Failed
        return 1
fi


I18N_Status_Print_Env_Install "reprepro"
INSTALLER::setup_reprepro
if [ $? -ne 0 ]; then
        I18N_Status_Print_Env_Install_Failed
        return 1
fi


I18N_Status_Print_Env_Install "osslsigncode"
INSTALLER::setup_osslsigncode
if [ $? -ne 0 ]; then
        I18N_Status_Print_Env_Install_Failed
        return 1
fi


if [ ! -z "$PROJECT_PYTHON" ]; then
        I18N_Status_Print_Env_Install "python"
        INSTALLER::setup_python
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Env_Install_Failed
                return 1
        fi
fi


if [ ! -z "$PROJECT_GO" ]; then
        I18N_Status_Print_Env_Install "go"
        INSTALLER::setup_go
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Env_Install_Failed
                return 1
        fi
fi


if [ ! -z "$PROJECT_C" ] || [ ! -z "$PROJECT_NIM" ] || [ ! -z "$PROJECT_RUST" ]; then
        I18N_Status_Print_Env_Install "c"
        INSTALLER::setup_c "$PROJECT_OS" "$PROJECT_ARCH"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Env_Install_Failed
                return 1
        fi
fi


if [ ! -z "$PROJECT_DOTNET" ]; then
        I18N_Status_Print_Env_Install "dotnet"
        DOTNET_Setup
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Env_Install_Failed
                return 1
        fi
fi


if [ ! -z "$PROJECT_NIM" ]; then
        I18N_Status_Print_Env_Install "nim"
        INSTALLER::setup_nim "$PROJECT_OS" "$PROJECT_ARCH"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Env_Install_Failed
                return 1
        fi
fi


if [ ! -z "$PROJECT_ANGULAR" ]; then
        I18N_Status_Print_Env_Install "angular"
        INSTALLER::setup_angular "$PROJECT_OS" "$PROJECT_ARCH"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Env_Install_Failed
                return 1
        fi
fi




# report status
I18N_Status_Print_Run_Successful
return 0

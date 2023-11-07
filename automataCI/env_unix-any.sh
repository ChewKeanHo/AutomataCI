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

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/net/http.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/installer.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/msi.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/publishers/dotnet.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/publishers/homebrew.sh"




# begin service
OS::print_status info "Installing brew...\n"
HOMEBREW::setup
if [ $? -ne 0 ]; then
        OS::print_status error "install failed.\n"
        return 1
fi


OS::print_status info "Installing curl...\n"
HTTP::setup
if [ $? -ne 0 ]; then
        OS::print_status error "install failed.\n"
        return 1
fi


OS::print_status info "Installing msitools...\n"
MSI::setup
if [ $? -ne 0 ]; then
        OS::print_status error "install failed.\n"
        return 1
fi


OS::print_status info "Installing docker...\n"
INSTALLER::setup_docker
if [ $? -ne 0 ]; then
        OS::print_status error "install failed.\n"
        return 1
fi


OS::print_status info "Installing reprepro...\n"
INSTALLER::setup_reprepro
if [ $? -ne 0 ]; then
        OS::print_status error "install failed.\n"
        return 1
fi


OS::print_status info "Installing osslsigncode...\n"
INSTALLER::setup_osslsigncode
if [ $? -ne 0 ]; then
        OS::print_status error "install failed.\n"
        return 1
fi


if [ ! -z "$PROJECT_PYTHON" ]; then
        OS::print_status info "Installing python...\n"
        INSTALLER::setup_python
        if [ $? -ne 0 ]; then
                OS::print_status error "install failed.\n"
                return 1
        fi
fi


if [ ! -z "$PROJECT_GO" ]; then
        OS::print_status info "Installing go...\n"
        INSTALLER::setup_go
        if [ $? -ne 0 ]; then
                OS::print_status error "install failed.\n"
                return 1
        fi
fi


if [ ! -z "$PROJECT_C" ] || [ ! -z "$PROJECT_NIM" ] || [ ! -z "$PROJECT_RUST" ]; then
        OS::print_status info "Installing c...\n"
        INSTALLER::setup_c "$PROJECT_OS" "$PROJECT_ARCH"
        if [ $? -ne 0 ]; then
                OS::print_status error "install failed.\n"
                return 1
        fi
fi


if [ ! -z "$PROJECT_DOTNET" ]; then
        OS::print_status info "Installing dotnet...\n"
        DOTNET::setup
        if [ $? -ne 0 ]; then
                OS::print_status error "install failed.\n"
                return 1
        fi
fi


if [ ! -z "$PROJECT_NIM" ]; then
        OS::print_status info "Installing nim...\n"
        INSTALLER::setup_nim "$PROJECT_OS" "$PROJECT_ARCH"
        if [ $? -ne 0 ]; then
                OS::print_status error "install failed.\n"
                return 1
        fi
fi


if [ ! -z "$PROJECT_ANGULAR" ]; then
        OS::print_status info "Installing angular...\n"
        INSTALLER::setup_angular "$PROJECT_OS" "$PROJECT_ARCH"
        if [ $? -ne 0 ]; then
                OS::print_status error "install failed.\n"
                return 1
        fi
fi




# report status
OS::print_status success "\n\n"
return 0

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




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/changelog.sh"




# safety checking control surfaces
OS::print_status info "checking changelog availability...\n"
CHANGELOG_Is_Available
if [ $? -ne 0 ]; then
        OS::print_status error "changelog builder is unavailable.\n"
        return 1
fi




# execute
__file="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/changelog"
OS::print_status info "building ${PROJECT_VERSION} data changelog entry...\n"
CHANGELOG_Build_Data_Entry "$__file"
if [ $? -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi


OS::print_status info "building ${PROJECT_VERSION} deb changelog entry...\n"
CHANGELOG_Build_DEB_Entry \
        "$__file" \
        "$PROJECT_VERSION" \
        "$PROJECT_SKU" \
        "$PROJECT_DEBIAN_DISTRIBUTION" \
        "$PROJECT_DEBIAN_URGENCY" \
        "$PROJECT_CONTACT_NAME" \
        "$PROJECT_CONTACT_EMAIL" \
        "$(date -R)"
if [ $? -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi




# report status
return 0

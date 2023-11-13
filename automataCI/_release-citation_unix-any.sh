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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/time.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/citation.sh"




RELEASE::run_citation() {
        # execute
        OS::print_status info "generating citation file...\n"
        CITATION::build \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/CITATION.cff" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/docs/ABSTRACTS.txt" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/docs/CITATIONS.yml" \
                "$PROJECT_CITATION" \
                "$PROJECT_CITATION_TYPE" \
                "$(TIME_Format_ISO8601_Date "$(TIME_Now)")" \
                "$PROJECT_NAME" \
                "$PROJECT_VERSION" \
                "$PROJECT_LICENSE" \
                "$PROJECT_SOURCE_URL" \
                "$PROJECT_SOURCE_URL" \
                "$PROJECT_STATIC_URL" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_CONTACT_EMAIL"
        if [ $? -ne 0 ]; then
                OS::print_status error "generate failed.\n"
                return 1
        fi

        if [ -f "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/CITATION.cff" ]; then
                OS::print_status info "exporting CITATION.cff...\n"
                FS::copy_file \
                        "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}/CITATION.cff" \
                        "${PROJECT_PATH_ROOT}/CITATION.cff"
                if [ $? -ne 0 ]; then
                        OS::print_status error "export failed.\n"
                        return 1
                fi
        fi


        # report status
        return 0
}

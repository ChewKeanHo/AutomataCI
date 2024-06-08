#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-archive_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-cargo_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-chocolatey_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-deb_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-docker_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-flatpak_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-homebrew_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-ipk_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-lib_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-msi_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-pdf_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-pypi_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}/_package-rpm_unix-any.sh"




# report status
return 0

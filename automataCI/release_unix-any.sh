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

. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"

. "${LIBS_AUTOMATACI}/_release-cargo_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-changelog_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-checksum_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-citation_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-deb_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-docker_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-flatpak_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-homebrew_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-lib_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-npm_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-project_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-pypi_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-research_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-rpm_unix-any.sh"
. "${LIBS_AUTOMATACI}/_release-docsrepo_unix-any.sh"




# execute
RELEASE_Initiate_CHECKSUM
if [ $? -ne 0 ]; then
        return 1
fi


__recipe="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}"
__recipe="${__recipe}/release_unix-any.sh"
FS_Is_File "$__recipe"
if [ $? -eq 0 ]; then
        I18N_Detected "$__recipe"
        I18N_Parse "$__recipe"
        . "$__recipe"
        if [ $? -ne 0 ]; then
                I18N_Parse_Failed
                return 1
        fi
fi




# determine pathing variables
PACKAGE_DIRECTORY="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"




# initialize workspace and release job functions
OS_Is_Command_Available "RELEASE_Run_Pre_Processor"
if [ $? -eq 0 ]; then
        RELEASE_Run_Pre_Processor
        if [ $? -ne 0 ]; then
                return 1
        fi
fi


RELEASE_Setup_PROJECT # !! IMPORTANT !! - always the first
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE_Setup_DEB "$DEB_REPO"
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE_Setup_FLATPAK "$FLATPAK_REPO"
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE_Setup_HOMEBREW "$HOMEBREW_REPO"
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE_Setup_RPM "$RPM_REPO"
if [ $? -ne 0 ]; then
        return 1
fi




# scan through each product and run the release processing respectively
for TARGET in "$PACKAGE_DIRECTORY"/*; do
        if [ "${TARGET%.asc*}" != "$TARGET" ]; then
                continue # it's a gpg cert
        fi

        if [ "${TARGET%.gpg*}" != "$TARGET" ]; then
                continue # it's a gpg keyfile or cert
        fi

        I18N_Processing "$TARGET"


        RELEASE_Run_CARGO "$TARGET"
        if [ $? -ne 0 ]; then
                return 1
        fi


        RELEASE_Run_CITATION_CFF "$TARGET"
        if [ $? -ne 0 ]; then
                return 1
        fi


        RELEASE_Run_DEB "$TARGET" "$DEB_REPO" "$DEB_REPO_DATA"
        if [ $? -ne 0 ]; then
                return 1
        fi


        RELEASE_Run_DOCKER "$TARGET"
        if [ $? -ne 0 ]; then
                return 1
        fi


        RELEASE_Run_HOMEBREW "$TARGET" "$HOMEBREW_REPO"
        if [ $? -ne 0 ]; then
                return 1
        fi


        RELEASE_Run_LIBS "$TARGET"
        if [ $? -ne 0 ]; then
                return 1
        fi


        RELEASE_Run_NPM "$TARGET"
        if [ $? -ne 0 ]; then
                return 1
        fi


        RELEASE_Run_PYPI "$TARGET"
        if [ $? -ne 0 ]; then
                return 1
        fi


        RELEASE_Run_RESEARCH "$TARGET"
        if [ $? -ne 0 ]; then
                return 1
        fi


        RELEASE_Run_RPM "$TARGET" "$RPM_REPO"
        if [ $? -ne 0 ]; then
                return 1
        fi


        OS_Is_Command_Available "RELEASE_Run_Package_Processor"
        if [ $? -eq 0 ]; then
                RELEASE_Run_Package_Processor "$TARGET"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi
done




# run one-time directory-wide release processing functions
RELEASE_Update_DEB "$DEB_REPO" "$DEB_REPO_DATA"
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE_Update_RPM "$RPM_REPO"
if [ $? -ne 0 ]; then
        return 1
fi


OS_Is_Command_Available "RELEASE_Run_Post_Processor"
if [ $? -eq 0 ]; then
        RELEASE_Run_Post_Processor
        if [ $? -ne 0 ]; then
                return 1
        fi
fi




# conclude the release
RELEASE_Conclude_CHECKSUM "$PACKAGE_DIRECTORY" ## !! IMPORTANT !! - always the first
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE_Conclude_DEB "$DEB_REPO"
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE_Conclude_FLATPAK "$FLATPAK_REPO"
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE_Conclude_HOMEBREW "$HOMEBREW_REPO"
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE_Conclude_RPM "$RPM_REPO"
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE_Conclude_DOCS
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE_Conclude_CHANGELOG
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE_Conclude_PROJECT # !! IMPORTANT !! - always the last
if [ $? -ne 0 ]; then
        return 1
fi




# report status
I18N_Run_Successful
return 0

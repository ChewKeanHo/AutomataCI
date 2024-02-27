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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/compress/gz.sh"




CHANGELOG_Assemble_DEB() {
        ___directory="$1"
        ___target="$2"
        ___version="$3"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ]; then
                return 1
        fi

        ___directory="${___directory}/deb"
        ___target="${___target%.gz*}"


        # assemble file
        FS::remove_silently "$___target"
        FS::remove_silently "${___target}.gz"
        FS::make_housing_directory "$___target"

        ___initiated=""
        ___old_IFS="$IFS"
        while IFS="" read -r ___line || [ -n "$___line" ]; do
                FS::append_file "$___target" "$___line\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                ___initiated="true"
        done < "${___directory}/latest"
        IFS="$___old_IFS" && unset ___old_IFS ___line

        for ___tag in $(git tag --sort -version:refname); do
                FS::is_file "${___directory}/${___tag##*v}"
                if [ $? -ne 0 ]; then
                        continue
                fi

                if [ $(STRINGS_Is_Empty "$___initiated") -ne 0 ]; then
                        FS::append_file "$___target" "\n\n"
                fi

                ___old_IFS="$IFS"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        FS::append_file "$___target" "$___line\n"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi

                        ___initiated="true"
                done < "${___directory}/${___tag##*v}"
                IFS="$___old_IFS" && unset ___old_IFS ___line
        done
        unset ___tag


        # gunzip
        GZ_Create "$___target"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




CHANGELOG_Assemble_MD() {
        ___directory="$1"
        ___target="$2"
        ___version="$3"
        ___title="$4"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___title") -eq 0 ]; then
                return 1
        fi

        ___directory="${___directory}/data"


        # assemble file
        FS::remove_silently "$___target"
        FS::make_housing_directory "$___target"
        FS::write_file "$___target" "# ${___title}\n\n"
        FS::append_file "$___target" "\n## ${___version}\n\n"
        ___old_IFS="$IFS"
        while IFS="" read -r ___line || [ -n "$___line" ]; do
                FS::append_file "$___target" "* ${___line}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done < "${___directory}/latest"

        for ___tag in $(git tag --sort -version:refname); do
                FS::is_file "${___directory}/${___tag##*v}"
                if [ $? -ne 0 ]; then
                        continue
                fi

                FS::append_file "$___target" "\n\n## ${___tag}\n\n"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        FS::append_file "$___target" "* ${___line}\n"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                done < "${___directory}/${___tag##*v}"
        done
        IFS="$___old_IFS"
        unset ___old_IFS ___line ___tag


        # report status
        return 0
}




CHANGELOG_Assemble_RPM() {
        ___target="$1"
        ___resources="$2"
        ___date="$3"
        ___name="$4"
        ___email="$5"
        ___version="$6"
        ___cadence="$7"


        # validate input
        if [ $(STRINGS_Is_Empty "$___target") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___resources") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___date") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___email") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___cadence") -eq 0 ]; then
                return 1
        fi

        FS::is_file "$___target"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::is_directory "$___resources"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # emit stanza
        FS::append_file "$___target" "%%changelog\n"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # emit latest changelog
        FS::is_file "${___resources}/changelog/data/latest"
        if [ $? -eq 0 ]; then
                FS::append_file "$___target" \
                        "* ${___date} ${___name} <${___email}> - ${___version}-${___cadence}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                ___old_IFS="$IFS"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        ___line="${___line%%#*}"
                        if [ $(STRINGS_Is_Empty "$___line") -eq 0 ]; then
                                continue
                        fi

                        FS::append_file "$___target" "- ${___line}\n"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                done < "${___resources}/changelog/data/latest"
                IFS="$___old_IFS" && unset ___old_IFS ___line
        else
                FS::append_file "$___target" "# unavailable\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        # emit tailing newline
        FS::append_file "$___target" "\n"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




CHANGELOG_Build_Data_Entry() {
        ___directory="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ]; then
                return 1
        fi


        # get last tag from git log
        ___tag="$(git rev-list --tags --max-count=1)"
        if [ $(STRINGS_Is_Empty "$___tag") -eq 0 ]; then
                ___tag="$(git rev-list --max-parents=0 --abbrev-commit HEAD)"
        fi


        # generate log file from the latest to the last tag
        ___directory="${___directory}/data"
        FS::make_directory "$___directory"
        git log --pretty=format:"%s" HEAD..."$___tag" > "${___directory}/.latest"
        FS::is_file "${___directory}/.latest"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # good file, update the previous
        FS::remove_silently "${___directory}/latest" &> /dev/null
        FS::move "${___directory}/.latest" "${___directory}/latest"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report verdict
        return 0
}




CHANGELOG_Build_DEB_Entry() {
        ___directory="$1"
        ___version="$2"
        ___sku="$3"
        ___dist="$4"
        ___urgency="$5"
        ___name="$6"
        ___email="$7"
        ___date="$8"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___sku") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___dist") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___urgency") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___email") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___date") -eq 0 ]; then
                return 1
        fi

        FS::is_file "${___directory}/data/latest"
        if [ $? -ne 0 ]; then
                return 1
        fi

        case "$___dist" in
        stable|unstable|testing|experimental)
                ;;
        *)
                return 1
                ;;
        esac


        # all good. Generate the log fragment
        FS::make_directory "${___directory}/deb"


        # create the entry header
        FS::append_file "${___directory}/deb/.latest" "\
${___sku} (${___version}) ${___dist}; urgency=${___urgency}

"


        # generate body line-by-line
        ___old_IFS="$IFS"
        while IFS= read -r ___line || [ -n "$___line" ]; do
                ___line="${___line::80}"
                FS::append_file "${___directory}/deb/.latest" "  * ${___line}\n"
        done < "${___directory}/data/latest"
        IFS="$___old_IFS" && unset ___line ___old_IFS
        FS::append_file "${___directory}/deb/.latest" "\n"


        # create the entry signed-off
        FS::append_file "${___directory}/deb/.latest" \
                "-- ${___name} <${___email}>  ${___date}\n"


        # good file, update the previous
        FS::move "${___directory}/deb/.latest" "${___directory}/deb/latest"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




CHANGELOG_Compatible_DATA_Version() {
        ___directory="$1"
        ___version="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ]; then
                return 1
        fi


        # execute
        FS::is_file "${___directory}/data/${___version}"
        if [ $? -eq 0 ]; then
                return 1
        fi


        # report status
        return 0
}




CHANGELOG_Compatible_DEB_Version() {
        ___directory="$1"
        ___version="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ]; then
                return 1
        fi


        # execute
        FS::is_file "${___directory}/deb/${___version}"
        if [ $? -eq 0 ]; then
                return 1
        fi


        # report status
        return 0
}




CHANGELOG_Is_Available() {
        # execute
        OS::is_command_available "git"
        if [ $? -ne 0 ]; then
                return 1
        fi

        GZ_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




CHANGELOG_Seal() {
        ___directory="$1"
        ___version="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ]; then
                return 1
        fi

        FS::is_directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::is_file "${___directory}/data/latest"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::is_file "${___directory}/deb/latest"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        FS::move "${___directory}/data/latest" "${___directory}/data/${___version}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::move "${___directory}/deb/latest" "${___directory}/deb/${___version}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}

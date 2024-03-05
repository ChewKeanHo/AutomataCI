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
. "${LIBS_AUTOMATACI}/services/compilers/changelog.sh"




RPM_Create_Archive() {
        ___directory="$1"
        ___destination="$2"
        ___arch="$3"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___destination") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arch") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___destination"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # scan for spec file
        ___spec=""
        for ___file in "${___directory}/SPECS/"*; do
                FS_Is_File "$___file"
                if [ $? -ne 0 ]; then
                        continue
                fi

                ___spec="$___file"
                break
        done

        FS_Is_File "$___spec"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # archive into rpm
        ___current_path="$PWD" && cd "${___directory}"
        FS_Make_Directory "./BUILD"
        FS_Make_Directory "./BUILDROOT"
        FS_Make_Directory "./RPMS"
        FS_Make_Directory "./SOURCES"
        FS_Make_Directory "./SPECS"
        FS_Make_Directory "./SRPMCS"
        FS_Make_Directory "./tmp"
        rpmbuild --define "_topdir ${___directory}" \
                --define "debug_package %{nil}" \
                --define "__strip /bin/true" \
                --target "$___arch" \
                -ba "$___spec"
        ___process=$?
        cd "$___current_path" && unset ___current_path

        if [ $___process -ne 0 ]; then
                return 1
        fi


        # move to destination
        for ___package in "${___directory}/RPMS/${___arch}/"*; do
                FS_Is_File "$___package"
                if [ $? -ne 0 ]; then
                        continue
                fi

                FS_Remove_Silently "${___destination}/${___package##*/}"
                FS_Move "$___package" "$___destination"
        done


        # report status
        return 0
}




RPM_Create_Source_Repo() {
        ___is_simulated="$1"
        ___directory="$2"
        ___gpg_id="$3"
        ___url="$4"
        ___name="$5"
        ___sku="$6"


        # validate input
        if [ $(STRINGS_Is_Empty "$___is_simulated") -ne 0 ]; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___gpg_id") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___url") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___sku") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "${___directory}/SPEC_INSTALL"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "${___directory}/SPEC_FILES"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___url="${___url}/rpm"
        ___url="${___url%//rpm*}/rpm"
        ___key="usr/local/share/keyrings/${___sku}-keyring.gpg"
        ___filename="etc/yum.repos.d/${___sku}.repo"

        FS_Is_File "${___directory}/BUILD/${___filename##*/}"
        if [ $? -eq 0 ]; then
                return 10
        fi

        FS_Is_File "${___directory}/BUILD/${___key##*/}"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Make_Directory "${___directory}/BUILD"
        FS_Write_File "${___directory}/BUILD/${___filename##*/}" "\
# WARNING: AUTO-GENERATED - DO NOT EDIT!
[${___sku}]
name=${___name}
baseurl=${___url}
gpgcheck=1
gpgkey=file:///${___key}
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        GPG_Export_Public_Keyring "${___directory}/BUILD/${___key##*/}" "$___gpg_id"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Append_File "${___directory}/SPEC_INSTALL" "
install --directory %{buildroot}/${___filename%/*}
install -m 0644 ${___filename##*/} %{buildroot}/${___filename%/*}

install --directory %{buildroot}/${___key%/*}
install -m 0644 ${___key##*/} %{buildroot}/${___key%/*}
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Append_File "${___directory}/SPEC_FILES" "\
/${___filename}
/${___key}
"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




RPM_Create_Spec() {
        ___directory="$1"
        ___resources="$2"
        ___sku="$3"
        ___version="$4"
        ___cadence="$5"
        ___pitch="$6"
        ___name="$7"
        ___email="$8"
        ___website="$9"
        ___license="${10}"
        ___description_filepath="${11}"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___resources") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___sku") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___cadence") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___pitch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___email") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___website") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___license") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___resources"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # check if is the document already injected
        ___location="${___directory}/SPECS/${___sku}.spec"
        FS_Is_File "$___location"
        if [ $? -eq 0 ]; then
                return 2
        fi


        # create housing directory path
        FS_Make_Housing_Directory "$___location"


        # generate spec file's header
        FS_Write_File "$___location" "\
Name: ${___sku}
Version: ${___version}
Summary: ${___pitch}
Release: ${___cadence}
License: ${___license}
URL: ${___website}

"


        # generate spec file's description field
        FS_Append_File "$___location" "%%description\n"

        ___written=1
        FS_Is_File "${___directory}/SPEC_DESCRIPTION"
        if [ $? -eq 0 ]; then
                ___old_IFS="$IFS"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        if [ $(STRINGS_Is_Empty "$___line") -ne 0 ] &&
                                [ $(STRINGS_Is_Empty "${___line%%#*}") -eq 0 ]; then
                                continue
                        fi

                        FS_Append_File "$___location" "${___line%%#*}\n"
                done < "${___directory}/SPEC_DESCRIPTION"
                IFS="$___old_IFS" && unset ___old_IFS ___line

                FS_Remove_Silently "${___directory}/SPEC_DESCRIPTION"
                ___written=0
        fi

        FS_Is_File "$___description_filepath"
        if [ $? -eq 0 ] && [ $___written -ne 0 ]; then
                ___old_IFS="$IFS"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        if [ $(STRINGS_Is_Empty "$___line") -ne 0 ] &&
                                [ $(STRINGS_Is_Empty "${___line%%#*}") -eq 0 ]; then
                                continue
                        fi

                        FS_Append_File "$___location" "${___line%%#*}\n"
                done < "$___description_filepath"
                IFS="$___old_IFS" && unset ___old_IFS ___line
                ___written=0
        fi

        if [ $___written -ne 0 ]; then
                FS_Append_File "$___location" "\n"
        fi

        FS_Append_File "$___location" "\n"


        # generate spec file's prep field
        FS_Append_File "$___location" "%%prep\n"
        FS_Is_File "${___directory}/SPEC_PREPARE"
        if [ $? -eq 0 ]; then
                ___old_IFS="$IFS"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        ___line="${___line%%#*}"
                        if [ $(STRINGS_Is_Empty "$___line") -eq 0 ]; then
                                continue
                        fi

                        FS_Append_File "$___location" "${___line}\n"
                done < "${___directory}/SPEC_PREPARE"
                IFS="$___old_IFS" && unset ___old_IFS ___line

                FS_Remove_Silently "${___directory}/SPEC_PREPARE"
        else
                FS_Append_File "$___location" "\n"
        fi
        FS_Append_File "$___location" "\n"


        # generate spec file's build field
        FS_Append_File "$___location" "%%build\n"
        FS_Is_File "${___directory}/SPEC_BUILD"
        if [ $? -eq 0 ]; then
                ___old_IFS="$IFS"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        ___line="${___line%%#*}"
                        if [ $(STRINGS_Is_Empty "$___line") -eq 0 ]; then
                                continue
                        fi

                        FS_Append_File "$___location" "${___line}\n"
                done < "${___directory}/SPEC_BUILD"
                IFS="$___old_IFS" && unset ___old_IFS ___line

                FS_Remove_Silently "${___directory}/SPEC_BUILD"
        else
                FS_Append_File "$___location" "\n"
        fi
        FS_Append_File "$___location" "\n"


        # generate spec file's install field
        FS_Append_File "$___location" "%%install\n"
        FS_Is_File "${___directory}/SPEC_INSTALL"
        if [ $? -eq 0 ]; then
                ___old_IFS="$IFS"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        ___line="${___line%%#*}"
                        if [ $(STRINGS_Is_Empty "$___line") -eq 0 ]; then
                                continue
                        fi

                        FS_Append_File "$___location" "${___line}\n"
                done < "${___directory}/SPEC_INSTALL"
                IFS="$___old_IFS" && unset ___old_IFS ___line

                FS_Remove_Silently "${___directory}/SPEC_INSTALL"
        else
                FS_Append_File "$___location" "\n"
        fi
        FS_Append_File "$___location" "\n"


        # generate spec file's clean field
        FS_Append_File "$___location" "%%clean\n"
        FS_Is_File "${___directory}/SPEC_CLEAN"
        if [ $? -eq 0 ]; then
                ___old_IFS="$IFS"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        ___line="${___line%%#*}"
                        if [ $(STRINGS_Is_Empty "$___line") -eq 0 ]; then
                                continue
                        fi

                        FS_Append_File "$___location" "${___line}\n"
                done < "${___directory}/SPEC_CLEAN"
                IFS="$___old_IFS" && unset ___old_IFS ___line

                FS_Remove_Silently "${___directory}/SPEC_CLEAN"
        else
                FS_Append_File "$___location" "\n"
        fi
        FS_Append_File "$___location" "\n"


        # generate spec file's files field
        FS_Append_File "$___location" "%%files\n"
        FS_Is_File "${___directory}/SPEC_FILES"
        if [ $? -eq 0 ]; then
                ___old_IFS="$IFS"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        ___line="${___line%%#*}"
                        if [ $(STRINGS_Is_Empty "$___line") -eq 0 ]; then
                                continue
                        fi

                        FS_Append_File "$___location" "${___line}\n"
                done < "${___directory}/SPEC_FILES"
                IFS="$___old_IFS" && unset ___old_IFS ___line

                FS_Remove_Silently "${___directory}/SPEC_FILES"
        else
                FS_Append_File "$___location" "\n"
        fi
        FS_Append_File "$___location" "\n"


        # generate spec file's changelog field
        FS_Is_File "${___directory}/SPEC_CHANGELOG"
        if [ $? -eq 0 ]; then
                FS_Append_File "$___location" "%%changelog\n"

                ___old_IFS="$IFS"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        ___line="${___line%%#*}"
                        if [ $(STRINGS_Is_Empty "$___line") -eq 0 ]; then
                                continue
                        fi

                        FS_Append_File "$___location" "${___line}\n"
                done < "${___directory}/SPEC_CHANGELOG"
                IFS="$___old_IFS" && unset ___old_IFS ___line

                FS_Remove_Silently "${___directory}/SPEC_CHANGELOG"
        else
                ___date="$(date "+%a %b %d %Y")"
                CHANGELOG_Assemble_RPM \
                        "$___location" \
                        "$___resources" \
                        "$___date" \
                        "$___name" \
                        "$___email" \
                        "$___version" \
                        "1"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        # report status
        return 0
}




RPM_Is_Available() {
        ___os="$1"
        ___arch="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$___os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arch") -eq 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "rpmbuild"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # check compatible target cpu architecture
        case "$___os" in
        linux)
                ;;
        *)
                return 2
                ;;
        esac


        # check compatible target cpu architecture
        case "$___arch" in
        any)
                return 3
                ;;
        *)
                ;;
        esac


        # report status
        return 0
}




RPM_Is_Valid() {
        #___target="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        if [ "${1##*.}" = "rpm" ]; then
                return 0
        fi


        # return status
        return 1
}

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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/disk.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/io/time.sh"
. "${LIBS_AUTOMATACI}/services/compilers/changelog.sh"
. "${LIBS_AUTOMATACI}/services/checksum/md5.sh"
. "${LIBS_AUTOMATACI}/services/checksum/shasum.sh"




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
        ___metalink="$5"
        ___name="$6"
        ___scope="$7"
        ___sku="$8"


        # validate input
        if [ $(STRINGS_Is_Empty "$___is_simulated") -ne 0 ]; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___gpg_id") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___url") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___scope") -eq 0 ] ||
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
        ___key="usr/local/share/keyrings/${___sku}-keyring.gpg"
        ___filename="etc/yum.repos.d/${___sku}.repo"

        if [ $(STRINGS_Is_Empty "$___metalink") -ne 0 ]; then
                ___url="\
#baseurl=${___url} # note: flat repository - only for reference
metalink=${___metalink}
"
        else
                ___url="\
baseurl=${___url}
"
        fi

        FS_Is_File "${___directory}/BUILD/$(FS_Get_File "$___filename")"
        if [ $? -eq 0 ]; then
                return 10
        fi

        FS_Is_File "${___directory}/BUILD/$(FS_Get_File "$___key")"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Make_Directory "${___directory}/BUILD"
        FS_Write_File "${___directory}/BUILD/$(FS_Get_File "$___filename")" "\
# WARNING: AUTO-GENERATED - DO NOT EDIT!
[${___scope}-${___sku}]
name=${___name}
${___url}
gpgcheck=1
gpgkey=file:///${___key}
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        GPG_Export_Public_Keyring "${___directory}/BUILD/$(FS_Get_File "$___key")" "$___gpg_id"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Append_File "${___directory}/SPEC_INSTALL" "
install --directory %{buildroot}/$(FS_Get_Directory "$___filename")
install -m 0644 $(FS_Get_File "$___filename") %{buildroot}/$(FS_Get_Directory "$___filename")

install --directory %{buildroot}/$(FS_Get_Directory "$___key")
install -m 0644 $(FS_Get_File "$___key") %{buildroot}/$(FS_Get_Directory "$___key")
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




RPM_Flatten_Repo() {
        ___repo_directory="$1"
        ___filename_repomdxml="$2"
        ___filename_metalink="$3"
        ___base_url="$4"


        # validate input
        if [ $(STRINGS_Is_Empty "$___repo_directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___filename_repomdxml") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___filename_metalink") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___base_url") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___repo_directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "${___repo_directory}/repodata"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "${___repo_directory}/repodata/repomd.xml"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ___repomd="${___repo_directory}/repomd.xml"
        if [ $(STRINGS_Is_Empty "$___filename_repomdxml") -ne 0 ]; then
                ___repomd="${___repo_directory}/${___filename_repomdxml}"
        fi

        ___metalink="${___repo_directory}/METALINK_RPM"
        if [ $(STRINGS_Is_Empty "$___filename_metalink") -ne 0 ]; then
                ___metalink="${___repo_directory}/${___filename_metalink}"
        fi


        # patch repomd.xml location fields and write to main directory
        FS_Remove_Silently "$___repomd"

        ___old_IFS="$IFS"
        while IFS= read -r ___line || [ -n "$___line" ]; do
                ## patch location fields
                if [ ! "${___line##*<location href=\"repodata/}" = "$___line" ]; then
                        FS_Append_File "$___repomd" "\
${___line%%<location*}<location href=\"${___line##*<location href=\"repodata/}
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi

                        continue
                elif [ ! "${___line##*<location href=\'repodata/}" = "$___line" ]; then
                        FS_Append_File "$___repomd" "\
${___line%%<location*}<location href='${___line##*<location href=\'repodata/}
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi

                        continue
                fi

                ## nothing else so write it in.
                FS_Append_File "$___repomd" "${___line}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done < "${___repo_directory}/repodata/repomd.xml"
        IFS="$___old_IFS" && unset ___old_IFS

        FS_Remove "${___repo_directory}/repodata/repomd.xml"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # export all metadata files to main directory
        for ___file in "${___repo_directory}/repodata/"*; do
                FS_Is_File "$___file"
                if [ $? -ne 0 ]; then
                        continue
                fi

                ___dest="${___repo_directory}/$(FS_Get_File "$___file")"
                FS_Remove_Silently "$___dest"
                FS_Move "$___file" "$___dest"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done

        FS_Remove "${___repo_directory}/repodata"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # create RPM_Metalink
        ___time="$(TIME_Now)"
        ___url="${___base_url}/$(FS_Get_File "$___repomd")"

        FS_Remove_Silently "$___metalink"
        FS_Write_File "$___metalink" "\
<?xml version='1.0' encoding='utf-8'?>
<metalink version='3.0' \
xmlns='http://www.metalinker.org/' \
type='dynamic' \
pubdate='$(TIME_Format_Datetime_RFC5322_UTC "$___time")' \
generator='mirrormanager' \
xmlns:mm0='http://fedorahosted.org/mirrormanager'>
 <files>
  <file name='$(FS_Get_File "$___repomd")'>
   <mm0:timestamp>${___time}</mm0:timestamp>
   <size>$(DISK_Calculate_Size_File_Byte "$___repomd")</size>
   <verification>
    <hash type='md5'>$(MD5_Create_From_File "$___repomd")</hash>
    <hash type='sha1'>$(SHASUM_Create_From_File "$___repomd" "1")</hash>
    <hash type='sha256'>$(SHASUM_Create_From_File "$___repomd" "256")</hash>
    <hash type='sha512'>$(SHASUM_Create_From_File "$___repomd" "512")</hash>
   </verification>
   <resources maxconnections='1'>
     <url protocol='https' type='https' preference='100'>${___url}</url>
   </resources>
  </file>
 </files>
</metalink>
"
        if [ $? -ne 0 ]; then
                return 1
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


        # check compatible target os
        case "$___os" in
        linux|any)
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




RPM_Register() {
        #___workspace="$1"
        #___source="$2"
        #___target="$3"
        #___is_directory="$4"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$3") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        # write into SPEC_INSTALL
        ___spec="${1}/SPEC_INSTALL"
        if [ $(STRINGS_Is_Empty "$4") -ne 0 ]; then
                ___content="\
mkdir -p %{buildroot}/${3}
cp -r $(FS_Get_Directory "$2") %{buildroot}/${3}/.
"
        else
                ___content="\
mkdir -p %{buildroot}/$(FS_Get_Directory "$3")
cp -r ${2} %{buildroot}/${3}
"
        fi

        FS_Append_File "$___spec" "$___content"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # write into SPEC_FILES
        ___spec="${1}/SPEC_FILES"
        ___content="/${3}"
        if [ $(STRINGS_Is_Empty "$4") -ne 0 ]; then
                ___content="${___content}/$(FS_Get_Directory "$2")"
        fi
        ___content="${___content}\n"
        FS_Append_File "$___spec" "$___content"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}

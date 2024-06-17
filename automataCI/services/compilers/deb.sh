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
. "${LIBS_AUTOMATACI}/services/io/disk.sh"
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/io/time.sh"
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/archive/ar.sh"
. "${LIBS_AUTOMATACI}/services/crypto/gpg.sh"
. "${LIBS_AUTOMATACI}/services/checksum/md5.sh"
. "${LIBS_AUTOMATACI}/services/publishers/unix.sh"




DEB_Create_Archive() {
        ___directory="$1"
        ___destination="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "${___directory}/control"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "${___directory}/data"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "${___directory}/control/control"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # to workspace directory
        ___current_path="$PWD"


        # package control
        cd "${___directory}/control"
        TAR_Create_XZ "${___directory}/control.tar.xz" "."
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi


        # package data
        cd "${___directory}/data"
        TAR_Create_XZ "${___directory}/data.tar.xz" "*"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi


        # generate debian-binary
        cd "${___directory}"
        FS_Write_File "${___directory}/debian-binary" "2.0\n"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi


        # archive into deb
        ___file="package.deb"
        AR_Create "$___file" "debian-binary control.tar.xz data.tar.xz"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi


        # move to destination
        FS_Remove_Silently "$___destination"
        FS_Move "$___file" "$___destination"
        ___process=$?


        # return to current directory
        cd "$___current_path" && unset ___current_path


        # report status
        if [ $___process -ne 0 ]; then
                return 1
        fi

        return 0
}




DEB_Create_Changelog() {
        ___location="$1"
        ___filepath="$2"
        ___sku="$3"


        # validate input
        if [ $(STRINGS_Is_Empty "$___location") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___filepath") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___sku") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$___filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # create housing directory path
        FS_Make_Housing_Directory "$___location"
        FS_Remove_Silently "$___location"


        # copy processed file to target location
        FS_Copy_File "$___filepath" "$___location"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DEB_Create_Checksum() {
        #___directory="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # prepare workspace
        ___location="${1}/control/md5sums"
        FS_Remove_Silently "$___location"
        FS_Make_Housing_Directory "$___location"


        # checksum every items
        for ___line in $(find "${1}/data" -type f); do
                ___checksum="$(MD5_Create_From_File "$___line") ${___line}"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                ___line="${___line##*${1}/data/}"
                ___checksum="${___checksum%% *}"
                FS_Append_File "$___location" "${___checksum} ${___line}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done


        # report status
        return 0
}




DEB_Create_Control() {
        ___directory="$1"
        ___resources="$2"
        ___sku="$3"
        ___version="$4"
        ___arch="$5"
        ___os="$6"
        ___name="$7"
        ___email="$8"
        ___website="$9"
        ___pitch="${10}"
        ___priority="${11}"
        ___section="${12}"
        ___description_filepath="${13}"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___resources") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___sku") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___email") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___website") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___pitch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___priority") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___section") -eq 0 ]; then
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

        case "$___priority" in
        required|important|standard|optional|extra)
                ;;
        *)
                return 1
                ;;
        esac


        # prepare workspace
        ___arch="$(DEB_Get_Architecture "$___os" "$___arch")"
        ___location="${___directory}/control/control"
        FS_Make_Housing_Directory "${___location}"
        FS_Remove_Silently "${___location}"


        # generate control file
        ___size="$(DISK_Calculate_Size_Directory_KB "${___directory}/data")"
        if [ $(STRINGS_Is_Empty "$___size") -eq 0 ]; then
                return 1
        fi

        FS_Write_File "$___location" "\
Package: $___sku
Version: $___version
Architecture: $___arch
Maintainer: $___name <$___email>
Installed-Size: $___size
Section: $___section
Priority: $___priority
Homepage: $___website
Description: $___pitch
"


        # append description data file
        FS_Is_File "$___description_filepath"
        if [ $? -ne 0 ]; then
                return 0 # report status early
        fi

         ___old_IFS="$IFS"
        while IFS="" read -r ___line || [ -n "$___line" ]; do
                if [ $(STRINGS_Is_Empty "$___line") -ne 0 ] &&
                        [ $(STRINGS_Is_Empty "${___line%%#*}") -eq 0 ]; then
                        continue
                fi

                if [ $(STRINGS_Is_Empty "${___line}") -eq 0 ]; then
                        ___line=" ."
                else
                        ___line=" ${___line}"
                fi

                FS_Append_File "$___location" "${___line}\n"
        done < "${___description_filepath}"
        IFS="$___old_IFS" && unset ___old_IFS ___line


        # report status
        return 0
}




DEB_Create_Source_List() {
        ___directory="$1"
        ___gpg_id="$2"
        ___url="$3"
        ___component="$4"
        ___distribution="$5"
        ___keyring="$6"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___url") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___component") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___distribution") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___keyring") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$___gpg_id") -eq 0 ] && [ $(OS_Is_Run_Simulated) -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___key="usr/local/share/keyrings/${___keyring}-keyring.gpg"
        ___filename="${___directory}/data/etc/apt/sources.list.d/${___keyring}.list"

        FS_Is_File "$___filename"
        if [ $? -eq 0 ]; then
                return 10
        fi

        FS_Is_File "${___directory}/data/${___key}"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Make_Housing_Directory "$___filename"
        if [ "${___distribution%%/*}" = "$___distribution" ]; then
                # it's a pool repository
                FS_Write_File "$___filename" "\
# WARNING: AUTO-GENERATED - DO NOT EDIT!
deb [signed-by=/${___key}] ${___url} ${___distribution} ${__component}
"
        else
                # it's a flat repository
                FS_Write_File "$___filename" "\
# WARNING: AUTO-GENERATED - DO NOT EDIT!
deb [signed-by=/${___key}] ${___url} ${___distribution}
"
        fi
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Make_Housing_Directory "${___directory}/data/${___key}"
        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                FS_Write_File "${___directory}/data/${___key}" ""
        else
                GPG_Export_Public_Keyring "${___directory}/data/${___key}" "$___gpg_id"
        fi
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DEB_Get_Architecture() {
        #___os="$1"
        #___arch="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                printf -- ""
                return 1
        fi


        # execute
        case "$1" in
        any)
                ___output="all-"
                ;;
        linux)
                ___output=""
                ;;
        dragonfly)
                ___output="dragonflybsd-"
                ;;
        *)
                ___output="${1}-"
                ;;
        esac
        ___output="${___output}$(UNIX_Get_Arch "$2")"
        if [ "$___output" = "all-all" ]; then
                ___output="all"
        fi


        # report status
        ___output="$(STRINGS_To_Lowercase "$___output")"
        printf -- "%b" "$___output"
        return 0
}




DEB_Is_Available() {
        #___os="$1"
        #___arch="$2"

        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi


        # validate dependencies
        MD5_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        SHASUM_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        TAR_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        AR_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        DISK_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        GPG_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "find"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # check compatible target os
        case "$1" in
        windows|darwin)
                return 2
                ;;
        *)
                # accepted
                ;;
        esac


        # check compatible target cpu architecture
        case "$2" in
        any)
                return 3
                ;;
        *)
                # accepted
                ;;
        esac


        # report status
        return 0
}




DEB_Is_Valid() {
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
        if [ "${1##*.}" = "deb" ]; then
                return 0
        fi


        # return status
        return 1
}




DEB_Publish() {
        ___repo_directory="$1"
        ___data_directory="$2"
        ___workspace_directory="$3"
        ___target="$4"
        ___distribution="$5"
        ___component="$6"


        # validate input
        if [ $(STRINGS_Is_Empty "$___repo_directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___data_directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___workspace_directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___distribution") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___component") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___repo_directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "$___target"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___directory_unpack="${___workspace_directory}/deb"
        ___repo_is_pool=1
        if [ "${___distribution%%/*}" = "$___distribution" ]; then
                ## it's a pool repository
                ___repo_is_pool=0
        else
                ## it's a flat repository
                ___distribution="${___distribution%%/*}"
        fi


        # unpack package control section
        FS_Remake_Directory "$___directory_unpack"
        DEB_Unpack "$___directory_unpack" "$___target" "control"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "${___directory_unpack}/control/control"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # parse package control data
        ___value_type="binary" # currently support this for now
        ___value_package=""
        ___value_version=""
        ___value_arch=""
        ___value_maintainer=""
        ___value_buffer=""
        ___value_size="$(DISK_Calculate_Size_File_Byte "$___target")"
        ___value_sha256="$(SHASUM_Create_From_File "$___target" "256")"
        ___value_sha1="$(SHASUM_Create_From_File "$___target" "1")"
        ___value_md5="$(MD5_Create_From_File "$___target")"
        ___value_description=""

        ___old_IFS="$IFS"
        while IFS= read -r ___line || [ -n "$___line" ]; do
                if [ "${___line#*Package: }" != "${___line}" ]; then
                        if [ $(STRINGS_Is_Empty "$___value_package") -ne 0 ]; then
                                ## invalid control file - multiple same fields detected
                                return 1
                        fi

                        ___value_package="${___line#*Package: }"
                        continue
                fi

                if [ "${___line#*Version: }" != "${___line}" ]; then
                        if [ $(STRINGS_Is_Empty "$___value_version") -ne 0 ]; then
                                ## invalid control file - multiple same fields detected
                                return 1
                        fi

                        ___value_version="${___line#*Version: }"
                        continue
                fi

                if [ "${___line#*Architecture: }" != "${___line}" ]; then
                        if [ $(STRINGS_Is_Empty "$___value_arch") -ne 0 ]; then
                                ## invalid control file - multiple same fields detected
                                return 1
                        fi

                        ___value_arch="${___line#*Architecture: }"
                        continue
                fi

                if [ "${___line#*Maintainer: }" != "${___line}" ]; then
                        if [ $(STRINGS_Is_Empty "$___value_maintainer") -ne 0 ]; then
                                ## invalid control file - multiple same fields detected
                                return 1
                        fi

                        ___value_maintainer="${___line#*Maintainer: }"
                        continue
                fi

                if [ "${___line#*Description: }" != "${___line}" ]; then
                        if [ $(STRINGS_Is_Empty "$___value_description") -ne 0 ]; then
                                ## invalid control file - multiple same fields detected
                                return 1
                        fi

                        ___value_description="$___line"
                        continue
                fi

                if [ $(STRINGS_Is_Empty "$___value_description") -eq 0 ]; then
                        if [ $(STRINGS_Is_Empty "$___value_buffer") -ne 0 ]; then
                                ___value_buffer="${___value_buffer}\n"
                        fi

                        ___value_buffer="${___value_buffer}${___line}"
                else
                        if [ $(STRINGS_Is_Empty "$___value_description") -ne 0 ]; then
                                ___value_description="${___value_description}\n"
                        fi

                        ___value_description="${___value_description}${___line}"
                fi
        done < "${___directory_unpack}/control/control"
        IFS="$___old_IFS" && unset ___old_IFS


        # sanitize package metadata
        if [ $(STRINGS_Is_Empty "$___value_type") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___value_package") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___value_version") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___value_arch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___value_maintainer") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___value_size") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___value_sha256") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___value_sha1") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___value_md5") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___value_description") -eq 0 ]; then
                return 1
        fi


        # process filename
        ___value_filename="${___value_package}_${___value_version}_${___value_arch}.deb"
        if [ $___repo_is_pool -eq 0 ]; then
                ___value_filename="${___value_package}/${___value_filename}"
                ___value_filename="$(printf -- "%.1s" "$(FS_Get_File "$___value_package")")/${___value_filename}"
                ___value_filename="pool/${___distribution}/${___value_filename}"
        fi


        # write to package database
        ___dest="${___value_package}_${___value_version}_${___value_arch}"
        if [ $___repo_is_pool -eq 0 ]; then
                ___dest="${___value_type}-${___value_arch}/${___dest}"
                ___dest="${___component}/${___dest}"
                ___dest="${___distribution}/${___dest}"
        fi
        ___dest="${___data_directory}/packages/${___dest}"
        FS_Is_File "$___dest"
        if [ $? -eq 0 ]; then
                return 1 # duplicated package - already registered
        fi

        FS_Make_Housing_Directory "$___dest"
        FS_Write_File "$___dest" "\
Package: ${___value_package}
Version: ${___value_version}
Architecture: ${___value_arch}
Maintainer: ${___value_maintainer}
${___value_buffer}
Filename: ${___value_filename}
Size: ${___value_size}
SHA256: ${___value_sha256}
SHA1: ${___value_sha1}
MD5sum: ${___value_md5}
${___value_description}
"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # write to arch database
        ___dest="${___data_directory}/arch/${___value_arch}"
        FS_Make_Housing_Directory "$___dest"
        FS_Append_File "$___dest" "${___value_filename}\n"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # export deb payload to destination
        ___dest="${___repo_directory}/${___value_filename}"
        FS_Is_File "$___dest"
        if [ $? -ne 0 ]; then
                FS_Make_Housing_Directory "$___dest"
                if [ $___repo_is_pool -eq 0 ]; then
                        FS_Copy_File "$___target" "$___dest"
                else
                        FS_Move "$___target" "$___dest"
                fi
                if [ $? -ne 0 ]; then
                        return 1
                fi
        elif [ "$___target" != "$___dest" ]; then
                return 1 # duplicated package existence or corrupted run
        fi


        # report status
        return 0
}




DEB_Publish_Conclude() {
        ___repo_directory="$1"
        ___data_directory="$2"
        ___distribution="$3"
        ___arch_list="$4"
        ___component="$5"
        ___codename="$6"
        ___gpg_id="$7"


        # validate input
        if [ $(STRINGS_Is_Empty "$___repo_directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___data_directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___distribution") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___component") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___codename") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___gpg_id") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___repo_directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___data_directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "find"
        if [ $? -ne 0 ]; then
                return 1
        fi

        GPG_Is_Available "$___gpg_id"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___directory_package="${___data_directory}/packages"
        ___repo_is_pool=1
        if [ "${___distribution%%/*}" = "$___distribution" ]; then
                # it's a pool repository
                ___repo_is_pool=0
                ___repo_directory="${___repo_directory}/dists"
        else
                ## it's a flat repository
                ___distribution="${___distribution%%/*}"
        fi


        # formulate arch list if empty
        if [ $(STRINGS_Is_Empty "$___arch_list") -eq 0 ]; then
                ___old_IFS="$IFS"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        if [ $(STRINGS_Is_Empty "$___arch_list") -ne 0 ]; then
                                ___arch_list="${___arch_list} "
                        fi

                        ___arch_list="${___arch_list}$(FS_Get_File "$___line")"
                done <<EOF
$(find "${___data_directory}/arch" -type f)
EOF
                IFS="$___old_IFS" && unset ___old_IFS
        fi

        if [ $(STRINGS_Is_Empty "$___arch_list") -eq 0 ]; then
                return 1
        fi


        # purge all Package and Release files from repository
        if [ $___repo_is_pool -eq 0 ]; then
                FS_Remove_Silently "$___repo_directory"
        else
                ___old_IFS="$IFS"
                while IFS= read -r ___line || [ -n "$___line" ]; do
                        FS_Remove_Silently "$___line"
                done <<EOF
$(find "$___repo_directory" -type f \
        -name 'Packages' -o \
        -name 'Packages.gz' -o \
        -name 'Release' -o \
        -name 'Release.gpg' -o \
        -name 'InRelease' \
)
EOF
                IFS="$___old_IFS" && unset ___old_IFS
        fi


        # re-create all Package files
        ___old_IFS="$IFS"
        while IFS= read -r ___line || [ -n "$___line" ]; do
                ## get relative path
                ___line="${___line##*${___directory_package}/}"

                ## determine destination path
                ___dest="$(FS_Get_Directory "$___line")"
                if [ $___repo_is_pool -eq 0 ]; then
                        ___dest="${___repo_directory}/${___dest}"
                else
                        if [ ! "$___dest" = "$___line" ]; then
                                # skip - it is a pool mode package in flat mode operation
                                continue
                        fi

                        ___dest="${___repo_directory}"
                fi
                FS_Make_Directory "$___dest"

                ## append package entry
                FS_Is_File "${___dest}/Packages"
                if [ $? -eq 0 ]; then
                        FS_Append_File "${___dest}/Packages" "\n"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                fi

                while IFS= read -r ___content || [ -n "$___content" ]; do
                        FS_Append_File "${___dest}/Packages" "${___content}\n"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                done < "${___directory_package}/${___line}"
        done <<EOF
$(find "$___directory_package" -type f)
EOF
        IFS="$___old_IFS" && unset ___old_IFS

        ___old_IFS="$IFS"
        while IFS= read -r ___line || [ -n "$___line" ]; do
                ## gunzip all Package files
                FS_Copy_File "$___line" "${___line}.backup"
                FS_Remove_Silently "${___line}.gz"
                GZ_Create "$___line"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                FS_Move "${___line}.backup" "$___line"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                ## create corresponding legacy Release file for pool mode
                if [ $___repo_is_pool -eq 0 ]; then
                        ___arch="${___line##*${___repo_directory}/}"
                        ___arch="$(FS_Get_Directory "$___arch")"

                        ___suite="${___arch%%/*}"
                        ___arch="${___arch#*/}"

                        ___component="${___arch%%/*}"
                        ___arch="${___arch#*/}"

                        ___package_type="${___arch%%-*}"
                        ___arch="${___arch##*-}"

                        FS_Write_File "$(FS_Get_Directory "$___line")/Release" "\
Archive: ${___suite}
Component: ${___component}
Architecture: ${___arch}
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                fi
        done <<EOF
$(find "$___repo_directory" -type f -name 'Packages')
EOF
        IFS="$___old_IFS" && unset ___old_IFS


        # generate repository metadata
        if [ $___repo_is_pool -eq 0 ]; then
                ___repo_directory="${___repo_directory}/${___distribution}"
        fi
        ___dest_release="${___repo_directory}/Release"
        FS_Remove_Silently "$___dest_release"
        ___dest_inrelease="${___repo_directory}/InRelease"
        FS_Remove_Silently "$___dest_inrelease"
        ___dest_md5="${___repo_directory}/ReleaseMD5"
        FS_Remove_Silently "$___dest_md5"
        ___dest_sha1="${___repo_directory}/ReleaseSHA1"
        FS_Remove_Silently "$___dest_sha1"
        ___dest_sha256="${___repo_directory}/ReleaseSHA256"
        FS_Remove_Silently "$___dest_sha256"

        ___old_IFS="$IFS"
        while IFS= read -r ___line || [ -n "$___line" ]; do
                ___size="$(DISK_Calculate_Size_File_Byte "$___line")"
                ___path="${___line##${___repo_directory}/}"

                ___checksum="$(MD5_Create_From_File "$___line")"
                FS_Append_File "$___dest_md5" " ${___checksum} ${___size} ${___path}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                ___checksum="$(SHASUM_Create_From_File "$___line" "1")"
                FS_Append_File "$___dest_sha1" " ${___checksum} ${___size} ${___path}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                ___checksum="$(SHASUM_Create_From_File "$___line" "256")"
                FS_Append_File "$___dest_sha256" " ${___checksum} ${___size} ${___path}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done <<EOF
$(find "$___repo_directory" -type f -name 'Packages' -o -name 'Packages.gz' -o -name 'Release')
EOF
        IFS="$___old_IFS" && unset ___old_IFS


        # create root Release file
        FS_Write_File "$___dest_release" "\
Suite: ${___distribution}
Codename: ${___codename}
Date: $(TIME_Format_Datetime_RFC5322_UTC "$(TIME_Now)")
Architectures: ${___arch_list}
Components: ${___component}
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Append_File "$___dest_release" "MD5Sum:\n"
        if [ $? -ne 0 ]; then
                return 1
        fi
        ___old_IFS="$IFS"
        while IFS= read -r ___line || [ -n "$___line" ]; do
                FS_Append_File "$___dest_release" "${___line}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done < "$___dest_md5"
        IFS="$___old_IFS" && unset ___old_IFS
        FS_Remove "$___dest_md5"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Append_File "$___dest_release" "SHA1:\n"
        ___old_IFS="$IFS"
        while IFS= read -r ___line || [ -n "$___line" ]; do
                FS_Append_File "$___dest_release" "${___line}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done < "$___dest_sha1"
        IFS="$___old_IFS" && unset ___old_IFS
        FS_Remove "$___dest_sha1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Append_File "$___dest_release" "SHA256:\n"
        ___old_IFS="$IFS"
        while IFS= read -r ___line || [ -n "$___line" ]; do
                FS_Append_File "$___dest_release" "${___line}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done < "$___dest_sha256"
        IFS="$___old_IFS" && unset ___old_IFS
        FS_Remove "$___dest_sha256"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # create InRelease file
        GPG_Clear_Sign_File "$___dest_inrelease" "$___dest_release" "$___gpg_id"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # create Release.gpg file
        GPG_Detach_Sign_File "${___dest_release}.gpg" "$___dest_release" "$___gpg_id"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DEB_Unpack() {
        ___directory="$1"
        ___target="$2"
        ___unpack_type="$3"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "$___target"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Target_Exist "${___directory}/control"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Is_Target_Exist "${___directory}/data"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Is_Target_Exist "${___directory}/debian-binary"
        if [ $? -eq 0 ]; then
                return 1
        fi


        # execute
        # copy target into directory
        FS_Copy_File "$___target" "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # to workspace directory
        ___current_path="$PWD" && cd "$___directory"


        # ar extract outer layer
        ___source="./$(FS_Get_File "$___target")"
        AR_Extract "$___source"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi
        FS_Remove_Silently "$___source"

        ## unpack control.tar.*z by request
        if [ ! "$(STRINGS_To_Lowercase "$___unpack_type")" = "data" ]; then
                ___source="./control.tar.xz"
                ___dest="./control"
                FS_Make_Directory "$___dest"
                FS_Is_File "$___source"
                if [ $? -eq 0 ]; then
                        TAR_Extract_XZ "$___dest" "$___source"
                        ___process=$?
                else
                        ___source="./control.tar.gz"
                        FS_Is_File "$___source"
                        if [ $? -ne 0 ]; then
                                cd "$___current_path" && unset ___current_path
                                return 1
                        fi

                        TAR_Extract_GZ "$___dest" "$___source"
                        ___process=$?
                fi
                FS_Remove_Silently "$___source"
        fi

        if [ "$(STRINGS_To_Lowercase "$___unpack_type")" = "control" ]; then
                # stop as requested
                cd "$___current_path" && unset ___current_path


                # report status
                if [ $___process -ne 0 ]; then
                        return 1
                fi
                return 0
        fi


        # unpack data.tar.*z by request
        ___source="./data.tar.xz"
        ___dest="./data"
        FS_Make_Directory "$___dest"
        FS_Is_File "$___source"
        if [ $? -eq 0 ]; then
                TAR_Extract_XZ "$___dest" "$___source"
                ___process=$?
        else
                ___source="./data.tar.gz"
                FS_Is_File "$___source"
                if [ $? -ne 0 ]; then
                        cd "$___current_path" && unset ___current_path
                        return 1
                fi

                TAR_Extract_GZ "$___dest" "$___source"
                ___process=$?
        fi
        FS_Remove_Silently "$___source"

        ## return to current directory
        cd "$___current_path" && unset ___current_path


        # report status
        if [ $___process -ne 0 ]; then
                return 1
        fi
        return 0
}

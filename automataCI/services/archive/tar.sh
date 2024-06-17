#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
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
. "${LIBS_AUTOMATACI}/services/compress/xz.sh"




TAR_Is_Available() {
        # execute
        OS_Is_Command_Available "tar"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




TAR_Create() {
        #___destination="$1"
        #___source="$2"
        #___owner="$3"
        #___group="$4"


        # validate input
        if [ $(STRINGS_Is_Empty "$2") -eq 0 ] || [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi

        TAR_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # create tar archive
        if [ $(STRINGS_Is_Empty "$3") -ne 0 ] && [ $(STRINGS_Is_Empty "$4") -ne 0 ]; then
                tar --numeric-owner --group="$4" --owner="$3" -cvf "$1" $2
                if [ $? -ne 0 ]; then
                        return 1
                fi
        else
                tar -cvf "$1" $2
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        # report status
        return 0
}




TAR_Create_GZ() {
        #___destination="$1"
        #___source="$2"
        #___owner="$3"
        #___group="$4"


        # validate input
        if [ $(STRINGS_Is_Empty "$2") -eq 0 ] || [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi

        GZ_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ "${1%.tgz*}" != "$1" ]; then
                ___dest="${1%.tgz*}"
        else
                ___dest="${1%.tar.gz*}"
        fi


        # create tar archive
        TAR_Create "${___dest}.tar" "$2" "$3" "$4"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # compress archive
        GZ_Create "${___dest}.tar"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # rename to destination target
        if [ ! "$1" = "${___dest}.tar.gz" ]; then
                FS_Move "${___dest}.tar.gz" "$1"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        # report status
        return 0
}




TAR_Create_XZ() {
        #___destination="$1"
        #___source="$2"
        #___owner="$3"
        #___group="$4"


        # validate input
        if [ $(STRINGS_Is_Empty "$2") -eq 0 ] || [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi

        XZ_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ "${1%.txz*}" != "$1" ]; then
                ___dest="${1%.txz*}"
        else
                ___dest="${1%.tar.xz*}"
        fi


        # create tar archive
        TAR_Create "${___dest}.tar" "$2" "$3" "$4"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # compress archive
        XZ_Create "${___dest}.tar"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # rename to target
        if [ ! "$1" = "${___dest}.tar.xz" ]; then
                FS_Move "${___dest}.tar.xz" "$1"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        # report status
        return 0
}




TAR_Extract_GZ() {
        #___destination="$1"
        #___source="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi

        GZ_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # unpack tar.gz
        tar -C "$1" -xzf "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




TAR_Extract_XZ() {
        #___destination="$1"
        #___source="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi

        XZ_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # unpack tar.xz
        tar -C "$1" -xf "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}

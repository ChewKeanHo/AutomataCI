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




NOTARY_Apple_Is_Available() {
        # execute
        OS_Is_Command_Available "codesign"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "ditto"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "xcrun"
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$APPLE_DEVELOPER_ID") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$APPLE_KEYCHAIN_PROFILE") -eq 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NOTARY_Microsoft_Is_Available() {
        # execute
        OS_Is_Command_Available "osslsigncode"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "$MICROSOFT_CERT"
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$MICROSOFT_CERT_TYPE") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$MICROSOFT_CERT_TIMESTAMP") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$MICROSOFT_CERT_HASH") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$MICROSOFT_CERT_PASSWORD") -eq 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NOTARY_Setup_Microsoft() {
        # validate input
        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "osslsigncode"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        brew install osslsigncode


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




NOTARY_Sign_Apple() {
        #___destination="$1"
        #___file="$2"


        # validate input
        NOTARY_Apple_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        codesign --force --options runtime --deep --sign "$APPLE_DEVELOPER_ID" "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ditto -c -k --keepParent "$2" "${2}.zip"
        if [ $? -ne 0 ]; then
                return 1
        fi

        xcrun notarytool \
                submit \
                "${2}.zip" \
                --keychain-profile "$APPLE_KEYCHAIN_PROFILE" \
                --wait
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Remove_Silently "${2}.zip"

        xcrun stapler staple "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Move "$2" "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NOTARY_Sign_Microsoft() {
        ___destination="$1"
        ___file="$2"
        ___name="$3"
        ___website="$4"


        # validate input
        NOTARY_Microsoft_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$___name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___website") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___destination") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$___file"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        case "$MICROSOFT_CERT_TYPE" in
        CERT)
                FS_Is_File "$MICROSOFT_CERT_KEYFILE"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                FS_Remove_Silently "$___destination"
                osslsigncode sign \
                        -certs "$MICROSOFT_CERT" \
                        -h "$MICROSOFT_CERT_HASH" \
                        -key "$MICROSOFT_CERT_KEYFILE" \
                        -pass "$MICROSOFT_CERT_PASSWORD" \
                        -n "$___name" \
                        -i "$___website" \
                        -t "$MICROSOFT_CERT_TIMESTAMP" \
                        -in "$___file" \
                        -out "$___destination"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                ;;
        SPC)
                FS_Is_File "$MICROSOFT_CERT_KEYFILE"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                FS_Remove_Silently "$___destination"
                osslsigncode sign \
                        -spc "$MICROSOFT_CERT" \
                        -h "$MICROSOFT_CERT_HASH" \
                        -key "$MICROSOFT_CERT_KEYFILE" \
                        -pass "$MICROSOFT_CERT_PASSWORD" \
                        -n "$___name" \
                        -i "$___website" \
                        -t "$MICROSOFT_CERT_TIMESTAMP" \
                        -in "$___file" \
                        -out "$___destination"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                ;;
        PKCS12)
                FS_Remove_Silently "$___destination"
                osslsigncode sign \
                        -pkcs12 "$MICROSOFT_CERT" \
                        -h "$MICROSOFT_CERT_HASH" \
                        -pass "$MICROSOFT_CERT_PASSWORD" \
                        -n "$___name" \
                        -i "$___website" \
                        -t "$MICROSOFT_CERT_TIMESTAMP" \
                        -in "$___file" \
                        -out "$___destination"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                ;;
        *)
                return 1
                ;;
        esac


        # report status
        return 0
}

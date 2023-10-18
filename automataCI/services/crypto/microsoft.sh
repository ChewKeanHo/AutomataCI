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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




MICROSOFT::sign() {
        __destination="$1"
        __file="$2"
        __name="$3"
        __website="$4"


        # validate input
        MICROSOFT::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ -z "$__name" ] ||
                [ -z "$__website" ] ||
                [ ! -f "$__file" ] ||
                [ -z "$__destination" ]; then
                return 1
        fi


        # execute
        case "$MICROSOFT_CERT_TYPE" in
        CERT)
                if [ ! -f "$MICROSOFT_CERT_KEYFILE" ]; then
                        return 1
                fi

                FS::remove_silently "$__destination"
                osslsigncode sign \
                        -certs "$MICROSOFT_CERT" \
                        -h "$MICROSOFT_CERT_HASH" \
                        -key "$MICROSOFT_CERT_KEYFILE" \
                        -pass "$MICROSOFT_CERT_PASSWORD" \
                        -n "$__name" \
                        -i "$__website" \
                        -t "$MICROSOFT_CERT_TIMESTAMP" \
                        -in "$__file" \
                        -out "$__destination"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                ;;
        SPC)
                if [ ! -f "$MICROSOFT_CERT_KEYFILE" ]; then
                        return 1
                fi

                FS::remove_silently "$__destination"
                osslsigncode sign \
                        -spc "$MICROSOFT_CERT" \
                        -h "$MICROSOFT_CERT_HASH" \
                        -key "$MICROSOFT_CERT_KEYFILE" \
                        -pass "$MICROSOFT_CERT_PASSWORD" \
                        -n "$__name" \
                        -i "$__website" \
                        -t "$MICROSOFT_CERT_TIMESTAMP" \
                        -in "$__file" \
                        -out "$__destination"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                ;;
        PKCS12)
                FS::remove_silently "$__destination"
                osslsigncode sign \
                        -pkcs12 "$MICROSOFT_CERT" \
                        -h "$MICROSOFT_CERT_HASH" \
                        -pass "$MICROSOFT_CERT_PASSWORD" \
                        -n "$__name" \
                        -i "$__website" \
                        -t "$MICROSOFT_CERT_TIMESTAMP" \
                        -in "$__file" \
                        -out "$__destination"
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




MICROSOFT::is_available() {
        # execute
        if [ -z "$(type -t osslsigncode)" ]; then
                return 1
        fi

        if [ ! -f "$MICROSOFT_CERT" ]; then
                return 1
        fi

        if [ -z "$MICROSOFT_CERT_TYPE" ]; then
                return 1
        fi

        if [ -z "$MICROSOFT_CERT_TIMESTAMP" ]; then
                return 1
        fi

        if [ -z "$MICROSOFT_CERT_HASH" ]; then
                return 1
        fi

        if [ -z "$MICROSOFT_CERT_PASSWORD" ]; then
                return 1
        fi


        # report status
        return 0
}

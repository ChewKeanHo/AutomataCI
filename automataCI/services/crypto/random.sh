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
. "${LIBS_AUTOMATACI}/services/io/time.sh"




RANDOM_Create_BINARY() {
        #___length="$1"


        # execute
        printf -- "%s" "$(RANDOM_Create_Data "$1" '0-1')"
        return $?
}




RANDOM_Create_Data() {
        #___length="$1"
        #___charset="$2"


        # validate input
        if [ -n "$1" -a $1 -eq $1 2> /dev/null -a $1 -gt 0 ]; then
                ___length=$1
        else
                ___length=33
        fi

        if [ "$(STRINGS_Is_Empty "$2")" = "0" ]; then
                printf -- ""
                return 1
        fi

        if [ -z "$(type -t dd)" ]; then
                printf -- ""
                return 1
        fi

        if [ -z "$(type -t tr)" ]; then
                printf -- ""
                return 1
        fi

        if [ ! -e "/dev/urandom" ]; then
                printf -- ""
                return 1
        fi


        # execute
        ___output=""
        ___count=0

        # NOTE:
        #   (1) MacOS's 'tr' won't break itself when reading directly from
        #       /dev/urandom.
        #   (2) Using 'dd' directly against /dev/urandom cannot warrant the
        #       output length we wanted.
        #   (3) So, we do not have a choice but to perform loop capturing until
        #       we get exactly what we wanted.
        #   (4) If you have better idea without compromising crypto-randomness
        #       while improving the performance, please inform the maintainers.
        #   (5) For now, this is what we have. Blame note (1) for behaving
        #       funny especially coming from an organ-selling priced hardware.
        while [ $___count -ne $___length ]; do
                ___char="$(dd bs=1 if=/dev/urandom count=1 2> /dev/null \
                                | LC_ALL=C tr -dc "$2" 2> /dev/null)"
                if [ -z "$___char" ]; then
                        continue
                fi

                ___output="${___output}${___char}"

                # increase counter for successful capture
                ___count=$(($___count + ${#___char}))
        done


        # report status
        printf -- "%b" "$___output"
        return 0
}




RANDOM_Create_DECIMAL() {
        #___length="$1"


        # execute
        printf -- "%s" "$(RANDOM_Create_Data "$1" '0-9')"
        return $?
}




RANDOM_Create_HEX() {
        #___length="$1"


        # execute
        printf -- "%s" "$(RANDOM_Create_Data "$1" 'A-F0-9')"
        return $?
}




RANDOM_Create_STRING() {
        #___length="$1"
        #___charset="$2"


        # execute
        printf -- "%s" "$(RANDOM_Create_Data "$1" "${2:-a-zA-Z0-9}")"
        return $?
}




RANDOM_Create_UUID() {
        # execute
        ___length_data=24
        ___length_epoch=8

        ___data="$(RANDOM_Create_HEX "$___length_data")"
        ___epoch="$(printf -- "%X" "$(TIME_Now)")"

        ___output=""
        ___length_epoch=$(($___length_epoch - 1))
        ___length_data=$(($___length_data - 1))
        ___count=0
        while [ $___count -lt 32 ]; do
                case "$___count" in
                8|12|16|20)
                        # add uuid dashes at correct index
                        ___output="${___output}-"
                        ;;
                *)
                        # do nothing
                        ;;
                esac

                if [ "$(RANDOM_Create_BINARY 1)" = "1" ] && [ $___length_epoch -ge 0 ]; then
                        # gamble and add 1 character from epoch if won
                        ___remainder="${___epoch#?}"
                        ___output="${___output}${___epoch%"$___remainder"}"
                        ___epoch="$___remainder"
                        ___length_epoch=$(($___length_epoch - 1))
                elif [ $___length_data -ge 0 ]; then
                        # add random character otherwise
                        ___remainder="${___data#?}"
                        ___output="${___output}${___data%"$___remainder"}"
                        ___data="$___remainder"
                        ___length_data=$(($___length_data - 1))
                elif [ $___length_epoch -ge 0 ]; then
                        # only epoch left
                        ___remainder="${___epoch#?}"
                        ___output="${___output}${___epoch%"$___remainder"}"
                        ___epoch="$___remainder"
                        ___length_epoch=$(($___length_epoch - 1))
                else
                        # impossible error edge cases - return nothing and fail
                        #                               is better than faulty.
                        1>&2 printf -- "bail: %s \n" "$___output"
                        printf -- ""
                        return 1
                fi


                # increase counter since POSIX does not have C like for loop.
                ___count=$(($___count + 1))
        done


        # report status
        printf -- "%s" "$___output"
        return 0
}

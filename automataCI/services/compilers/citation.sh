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




CITATION::build() {
        __filepath="$1"
        __abstract_filepath="$2"
        __citation_filepath="$3"
        __cff_version="$4"
        __type="$5"
        __date="$6"
        __title="$7"
        __version="$8"
        __license="$9"
        __repo="${10}"
        __repo_code="${11}"
        __repo_artifact="${12}"
        __contact_name="${13}"
        __contact_website="${14}"
        __contact_email="${15}"


        # validate input
        if [ -z "$__cff_version" ]; then
                return 0 # requested to be disabled
        fi

        if [ -z "$__filepath" ] || [ -z "$__title" ] || [ -z "$__type" ]; then
                return 1
        fi

        if [ -z "$__citation_filepath" ] || [ ! -f "$__citation_filepath" ]; then
                return 1
        fi


        # execute
        FS::remove_silently "$__filepath"
        FS::make_housing_directory "$__filepath"
        FS::write_file "$__filepath" "\
# WARNING: auto-generated by AutomataCI

cff-version: \"${__cff_version}\"
type: \"${__type}\"
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ## date
        if [ ! -z "$__date" ]; then
                FS::append_file "$__filepath" "\
date-released: \"${__date}\"
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        ## title
        if [ ! -z "$__title" ]; then
                FS::append_file "$__filepath" "\
title: \"${__title}\"
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        ## version
        if [ ! -z "$__version" ]; then
                FS::append_file "$__filepath" "\
version: \"${__version}\"
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        ## license
        if [ ! -z "$__license" ]; then
                FS::append_file "$__filepath" "\
license: \"${__license}\"
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        ## repository
        if [ ! -z "$__repo" ]; then
                FS::append_file "$__filepath" "\
repository: \"${__repo}\"
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        ## repository-code
        if [ ! -z "$__repo_code" ]; then
                FS::append_file "$__filepath" "\
repository-code: \"${__repo_code}\"
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        ## repository-artifact
        if [ ! -z "$__repo_artifact" ]; then
                FS::append_file "$__filepath" "\
repository-artifact: \"${__repo_artifact}\"
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        ## url
        if [ ! -z "$__contact_website" ]; then
                FS::append_file "$__filepath" "\
url: \"${__contact_website}\"
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        ## contact
        if [ ! -z "$__contact_name" ] &&
                [ ! -z "$__contact_website" -o ! -z "$__contact_email" ]; then
                FS::append_file "$__filepath" "\
contact:
  - affiliation: \"${__contact_name}\"
"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                if [ ! -z "$__contact_email" ]; then
                        FS::append_file "$__filepath" "\
    email: \"${__contact_email}\"
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                fi

                if [ ! -z "$__contact_website" ]; then
                        FS::append_file "$__filepath" "\
    website: \"${__contact_website}\"
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                fi
        fi

        ## abstract
        if [ -f "$__abstract_filepath" ]; then
                        FS::append_file "$__filepath" "\
abstract: |-
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi

                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        if [ ! -z "$__line" -a -z "${__line%%#*}" ]; then
                                continue
                        fi

                        __line="${__line%%#*}"
                        if [ ! -z "$__line" ]; then
                                __line="  ${__line}"
                        fi

                        FS::append_file "$__filepath" "${__line}\n"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                done < "$__abstract_filepath"
                IFS="$__old_IFS" && unset __old_IFS
        fi

        ## other citations
        __old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                if [ ! -z "$__line" -a -z "${__line%%#*}" ]; then
                        continue
                fi

                __line="${__line%%#*}"
                if [ -z "$__line" ]; then
                        continue
                fi

                FS::append_file "$__filepath" "${__line}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done < "$__citation_filepath"
        IFS="$__old_IFS" && unset __old_IFS


        # report status
        return 0
}

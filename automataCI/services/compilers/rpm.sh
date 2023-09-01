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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/changelog.sh"




RPM::is_available() {
        __os="$1"
        __arch="$2"

        if [ -z "$__os" ] || [ -z "$__arch" ]; then
                unset __os __arch
                return 1
        fi

        # check compatible target os
        case "$__os" in
        windows|darwin)
                unset __os __arch
                return 2
                ;;
        *)
                ;;
        esac

        # check compatible target cpu architecture
        case "$__arch" in
        any)
                unset __os __arch
                return 3
                ;;
        *)
                ;;
        esac
        unset __os __arch

        # validate dependencies
        if [ -z "$(type -t 'rpmbuild')" ]; then
                return 1
        fi

        # report status
        return 0
}




RPM::create_spec() {
        __directory="$1"
        __resources="$2"
        __sku="$3"
        __version="$4"
        __cadence="$5"
        __pitch="$6"
        __name="$7"
        __email="$8"
        __website="$9"

        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__resources" ] ||
                [ ! -d "$__resources" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__version" ] ||
                [ -z "$__cadence" ] ||
                [ -z "$__pitch" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__website" ]; then
                unset __directory \
                        __resources \
                        __sku \
                        __version \
                        __cadence \
                        __pitch \
                        __name \
                        __email \
                        __website
                return 1
        fi

        # check if is the document already injected
        __location="${__directory}/SPECS/${__sku}.spec"
        if [ -f "$__location" ]; then
                unset __location \
                        __directory \
                        __resources \
                        __sku \
                        __version \
                        __cadence \
                        __pitch \
                        __name \
                        __email \
                        __website
                return 2
        fi

        # obtain license SPDX
        __license="proprietary"
        if [ -f "${__resources}/licenses/SPDX.txt" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        __license="$__line"
                        break
                done < "${__resources}/licenses/SPDX.txt"
                IFS="$__old_IFS" && unset __old_IFS __line
        fi

        # create housing directory path
        mkdir -p "${__location%/*}"

        # generate spec file's header
        printf -- "\
Name: ${__sku}
Version: ${__version}
Summary: ${__pitch}
Release: ${__cadence}

License: ${__license}
URL: ${__website}
" > "$__location"

        # generate spec file's description field
        printf -- "%%description\n" >> "$__location"
        if [ -f "${__directory}/SPEC_DESCRIPTION" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        printf -- "${__line}\n" >> "$__location"
                done < "${__directory}/SPEC_DESCRIPTION"
                IFS="$__old_IFS" && unset __old_IFS __line

                rm -f "${__directory}/SPEC_DESCRIPTION" &> /dev/null
        elif [ -f "${__resources}/packages/DESCRIPTION.txt" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        printf -- "%s\n" "${__line}" >> "$__location"
                done < "${__resources}/packages/DESCRIPTION.txt"
                IFS="$__old_IFS" && unset __old_IFS __line
        else
                printf -- "\n" >> "$__location"
        fi
        printf -- "\n" >> "$__location"

        # generate spec file's prep field
        printf -- "%%prep\n" >> "$__location"
        if [ -f "${__directory}/SPEC_PREPARE" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        printf -- "%s\n" "${__line}" >> "$__location"
                done < "${__directory}/SPEC_PREPARE"
                IFS="$__old_IFS" && unset __old_IFS __line

                rm -f "${__directory}/SPEC_PREPARE" &> /dev/null
        fi
        printf -- "\n" >> "$__location"

        # generate spec file's build field
        printf -- "%%build\n" >> "$__location"
        if [ -f "${__directory}/SPEC_BUILD" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        printf -- "%s\n" "${__line}" >> "$__location"
                done < "${__directory}/SPEC_BUILD"
                IFS="$__old_IFS" && unset __old_IFS __line

                rm -f "${__directory}/SPEC_BUILD" &> /dev/null
        fi
        printf -- "\n" >> "$__location"

        # generate spec file's install field
        printf -- "%%install\n" >> "$__location"
        if [ -f "${__directory}/SPEC_INSTALL" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        printf -- "%s\n" "${__line}" >> "$__location"
                done < "${__directory}/SPEC_INSTALL"
                IFS="$__old_IFS" && unset __old_IFS __line

                rm -f "${__directory}/SPEC_INSTALL" &> /dev/null
        fi
        printf -- "\n" >> "$__location"

        # generate spec file's clean field
        printf -- "%%clean\n" >> "$__location"
        if [ -f "${__directory}/SPEC_CLEAN" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        printf -- "%s\n" "${__line}" >> "$__location"
                done < "${__directory}/SPEC_CLEAN"
                IFS="$__old_IFS" && unset __old_IFS __line

                rm -f "${__directory}/SPEC_CLEAN" &> /dev/null
        fi
        printf -- "\n" >> "$__location"

        # generate spec file's files field
        printf -- "%%files\n" >> "$__location"
        if [ -f "${__directory}/SPEC_FILES" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        printf -- "%s\n" "${__line}" >> "$__location"
                done < "${__directory}/SPEC_FILES"
                IFS="$__old_IFS" && unset __old_IFS __line

                rm -f "${__directory}/SPEC_FILES" &> /dev/null
        fi
        printf -- "\n" >> "$__location"

        # generate changelog field
        if [ -f "${__directory}/SPEC_CHANGELOG" ]; then
                printf -- "%%changelog\n" >> "$__location"

                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        printf -- "%s\n" "${__line}" >> "$__location"
                done < "${__directory}/SPEC_CHANGELOG"
                IFS="$__old_IFS" && unset __old_IFS __line

                rm -f "${__directory}/SPEC_CHANGELOG" &> /dev/null
        else
                CHANGELOG::assemble_rpm \
                        "$__location" \
                        "$__resources" \
                        "$(date "+%a %b %d %Y")" \
                        "$__name" \
                        "$__email" \
                        "$__version" \
                        "1"
                __exit=$?
                if [ $? -ne 0 ]; then
                        __exit=1
                fi
        fi

        # report status
        unset __location \
                __license \
                __directory \
                __resources \
                __sku \
                __version \
                __cadence \
                __pitch \
                __name \
                __email \
                __website
        return 0
}

RPM::create_archive() {
        __directory="$1"
        __destination="$2"
        __sku="$3"
        __arch="$4"

        # validate input
        if [ -z "$__directory" ] ||
                [ -z "$__destination" ] ||
                [ -z "$__sku" ] ||
                [ ! -d "$__directory" ] ||
                [ ! -d "$__destination" ] ||
                [ ! -f "${__directory}/SPECS/${__sku}.spec" ]; then
                unset __directory \
                        __destination \
                        __sku \
                        __arch
                return 1
        fi


        # archive into rpm
        __current_path="$PWD" && cd "${__directory}"
        mkdir -p "./BUILD"
        mkdir -p "./BUILDROOT"
        mkdir -p "./RPMS"
        mkdir -p "./SOURCES"
        mkdir -p "./SPECS"
        mkdir -p "./SRPMCS"
        mkdir -p "./tmp"
        rpmbuild \
                --define "_topdir `pwd`" \
                --target "$__arch" \
                -ba "${__directory}/SPECS/${__sku}.spec"
        __exit=$?
        cd "$__current_path" && unset __current_path
        if [ $__exit -ne 0 ]; then
                unset __directory \
                        __destination \
                        __sku \
                        __arch
                return 1
        fi

        # move to destination
        for package in "${__directory}/RPMS/${__arch}/"*; do
                rm -f "${__destination}/${package##*/}" &> /dev/null
                mv "$package" "$__destination"
        done


        # mv package.deb "$__destination"
        __exit=0

        # report status
        unset __directory \
                __destination \
                __sku \
                __arch
        return $__exit
}

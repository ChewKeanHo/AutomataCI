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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/changelog.sh"




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
                return 1
        fi


        # change directory into workspace
        __current_path="$PWD" && cd "${__directory}"


        # archive into rpm
        FS::make_directory "./BUILD"
        FS::make_directory "./BUILDROOT"
        FS::make_directory "./RPMS"
        FS::make_directory "./SOURCES"
        FS::make_directory "./SPECS"
        FS::make_directory "./SRPMCS"
        FS::make_directory "./tmp"
        rpmbuild \
                --define "_topdir ${__directory}" \
                --define "debug_package %{nil}" \
                --define "__strip /bin/true" \
                --target "$__arch" \
                -ba "${__directory}/SPECS/${__sku}.spec"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi


        # return back to current path
        cd "$__current_path" && unset __current_path


        # move to destination
        for package in "${__directory}/RPMS/${__arch}/"*; do
                FS::remove_silently "${__destination}/${package##*/}"
                FS::move "$package" "$__destination"
        done


        # report status
        return 0
}




RPM::create_source_repo() {
        __is_simulated="$1"
        __directory="$2"
        __gpg_id="$3"
        __url="$4"
        __name="$5"
        __sku="$6"


        # validate input
        if [ ! -z "$__is_simulated" ]; then
                return 0
        fi

        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__gpg_id" ] ||
                [ -z "$__url" ] ||
                [ -z "$__name" ] ||
                [ -z "$__sku" ]; then
                return 1
        fi

        FS::is_file "${__directory}/SPEC_INSTALL"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::is_file "${__directory}/SPEC_FILES"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        __url="${__url}/rpm"
        __url="${__url%//rpm*}/rpm"
        __key="usr/local/share/keyrings/${__sku}-keyring.gpg"
        __filename="etc/yum.repos.d/${__sku}.repo"

        FS::is_file "${__directory}/BUILD/${__filename##*/}"
        if [ $? -eq 0 ]; then
                return 10
        fi

        FS::is_file "${__directory}/BUILD/${__key##*/}"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS::make_directory "${__directory}/BUILD"
        FS::write_file "${__directory}/BUILD/${__filename##*/}" "\
# WARNING: AUTO-GENERATED - DO NOT EDIT!
[${__sku}]
name=${__name}
baseurl=${__url}
gpgcheck=1
gpgkey=file:///${__key}
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        GPG::export_public_keyring "${__directory}/BUILD/${__key##*/}" "$__gpg_id"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::append_file "${__directory}/SPEC_INSTALL" "
install --directory %{buildroot}/${__filename%/*}
install -m 0644 ${__filename##*/} %{buildroot}/${__filename%/*}

install --directory %{buildroot}/${__key%/*}
install -m 0644 ${__key##*/} %{buildroot}/${__key%/*}
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::append_file "${__directory}/SPEC_FILES" "\
/${__filename}
/${__key}
"
        if [ $? -ne 0 ]; then
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
        __license="${10}"


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
                [ -z "$__website" ] ||
                [ -z "$__license" ]; then
                return 1
        fi


        # check if is the document already injected
        __location="${__directory}/SPECS/${__sku}.spec"
        if [ -f "$__location" ]; then
                return 2
        fi


        # create housing directory path
        FS::make_housing_directory "$__location"


        # generate spec file's header
        FS::write_file "$__location" "\
Name: ${__sku}
Version: ${__version}
Summary: ${__pitch}
Release: ${__cadence}
License: ${__license}
URL: ${__website}

"


        # generate spec file's description field
        FS::append_file "$__location" "%%description\n"
        if [ -f "${__directory}/SPEC_DESCRIPTION" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        FS::append_file "$__location" "${__line}\n"
                done < "${__directory}/SPEC_DESCRIPTION"
                IFS="$__old_IFS" && unset __old_IFS __line

                FS::remove_silently "${__directory}/SPEC_DESCRIPTION"
        elif [ -f "${__resources}/packages/DESCRIPTION.txt" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        FS::append_file "$__location" "${__line}\n"
                done < "${__resources}/packages/DESCRIPTION.txt"
                IFS="$__old_IFS" && unset __old_IFS __line
        else
                FS::append_file "$__location" "\n"
        fi
        FS::append_file "$__location" "\n"


        # generate spec file's prep field
        FS::append_file "$__location" "%%prep\n"
        if [ -f "${__directory}/SPEC_PREPARE" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        FS::append_file "$__location" "${__line}\n"
                done < "${__directory}/SPEC_PREPARE"
                IFS="$__old_IFS" && unset __old_IFS __line

                FS::remove_silently "${__directory}/SPEC_PREPARE"
        else
                FS::append_file "$__location" "\n"
        fi
        FS::append_file "$__location" "\n"


        # generate spec file's build field
        FS::append_file "$__location" "%%build\n"
        if [ -f "${__directory}/SPEC_BUILD" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        FS::append_file "$__location" "${__line}\n"
                done < "${__directory}/SPEC_BUILD"
                IFS="$__old_IFS" && unset __old_IFS __line

                FS::remove_silently "${__directory}/SPEC_BUILD"
        else
                FS::append_file "$__location" "\n"
        fi
        FS::append_file "$__location" "\n"


        # generate spec file's install field
        FS::append_file "$__location" "%%install\n"
        if [ -f "${__directory}/SPEC_INSTALL" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        FS::append_file "$__location" "${__line}\n"
                done < "${__directory}/SPEC_INSTALL"
                IFS="$__old_IFS" && unset __old_IFS __line

                FS::remove_silently "${__directory}/SPEC_INSTALL"
        else
                FS::append_file "$__location" "\n"
        fi
        FS::append_file "$__location" "\n"


        # generate spec file's clean field
        FS::append_file "$__location" "%%clean\n"
        if [ -f "${__directory}/SPEC_CLEAN" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        FS::append_file "$__location" "${__line}\n"
                done < "${__directory}/SPEC_CLEAN"
                IFS="$__old_IFS" && unset __old_IFS __line

                FS::remove_silently "${__directory}/SPEC_CLEAN"
        else
                FS::append_file "$__location" "\n"
        fi
        FS::append_file "$__location" "\n"


        # generate spec file's files field
        FS::append_file "$__location" "%%files\n"
        if [ -f "${__directory}/SPEC_FILES" ]; then
                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        FS::append_file "$__location" "${__line}\n"
                done < "${__directory}/SPEC_FILES"
                IFS="$__old_IFS" && unset __old_IFS __line

                FS::remove_silently "${__directory}/SPEC_FILES"
        else
                FS::append_file "$__location" "\n"
        fi
        FS::append_file "$__location" "\n"


        # generate spec file's changelog field
        if [ -f "${__directory}/SPEC_CHANGELOG" ]; then
                FS::append_file "$__location" "%%changelog\n"

                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        FS::append_file "$__location" "${__line}\n"
                done < "${__directory}/SPEC_CHANGELOG"
                IFS="$__old_IFS" && unset __old_IFS __line

                FS::remove_silently "${__directory}/SPEC_CHANGELOG"
        else
                __date="$(date "+%a %b %d %Y")"
                CHANGELOG::assemble_rpm \
                        "$__location" \
                        "$__resources" \
                        "$__date" \
                        "$__name" \
                        "$__email" \
                        "$__version" \
                        "1"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        # report status
        return 0
}




RPM::is_available() {
        __os="$1"
        __arch="$2"

        if [ -z "$__os" ] || [ -z "$__arch" ]; then
                return 1
        fi


        # validate dependencies
        if [ -z "$(type -t 'rpmbuild')" ]; then
                return 1
        fi


        # check compatible target os
        case "$__os" in
        windows|darwin)
                return 2
                ;;
        *)
                ;;
        esac


        # check compatible target cpu architecture
        case "$__arch" in
        any)
                return 3
                ;;
        *)
                ;;
        esac


        # report status
        return 0
}




RPM::is_valid() {
        #__target="$1"


        # validate input
        if [ -z "$1" ] || [ -d "$1" ] || [ ! -f "$1" ]; then
                return 1
        fi


        # execute
        if [ "${1##*.}" = "rpm" ]; then
                return 0
        fi


        # return status
        return 1
}

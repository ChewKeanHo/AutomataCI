#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# (0) initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




PACKAGE::assemble_docker_content() {
        __target="$1"
        __directory="$2"
        __target_name="$3"
        __target_os="$4"
        __target_arch="$5"

        # validate project
        FS::is_target_a_source "$__target"
        if [ $? -eq 0 ]; then
                return 10
        fi

        case "$__target_os" in
        linux)
                ;;
        *)
                return 10
                ;;
        esac

        # assemble the package
        __target="$1"
        FS::copy_file "$__target" "${__directory}/${PROJECT_SKU}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ "$PROJECT_OS" = "linux" ] && [ "$PROJECT_ARCH" = "amd64" ]; then
                OS::print_status info "transforming output file to full static binary...\n"
                staticx "${__directory}/${PROJECT_SKU}" "${__directory}/.${PROJECT_SKU}"
                if [ $? -ne 0 ]; then
                        OS::print_status error "transform failed.\n"
                        return 1
                fi

                mv "${__directory}/.${PROJECT_SKU}" "${__directory}/${PROJECT_SKU}"
                if [ $? -ne 0 ]; then
                        OS::print_status error "transform failed.\n"
                        return 1
                fi
        fi

        FS::touch_file "${__directory}/.blank"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # generate the Dockerfile
        __target="${1##*/}"
        FS::write_file "${__directory}/Dockerfile" "\
# Defining baseline image
FROM --platform=${__target_os}/${__target_arch} scratch
MAINTAINER ${PROJECT_CONTACT_NAME} <${PROJECT_CONTACT_EMAIL}>

# Defining environment variables
ENV ARCH ${__target_arch}
ENV OS ${__target_os}
ENV PORT 80

# Assemble the file structure
COPY .blank /tmp/.tmpfile
ADD ${PROJECT_SKU} /app/bin/${PROJECT_SKU}

# Set network port exposures
EXPOSE 80

# Set entry point
ENTRYPOINT [\"/app/bin/${PROJECT_SKU}\"]
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}

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
. "${LIBS_AUTOMATACI}/services/io/strings.sh"




DOCKER_Amend_Manifest() {
        #___tag="$1"
        #___list="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi


        # execute
        BUILDX_NO_DEFAULT_ATTESTATIONS=1 docker manifest create "$1" $2
        if [ $? -ne 0 ]; then
                return 1
        fi

        BUILDX_NO_DEFAULT_ATTESTATIONS=1 docker manifest push "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DOCKER_Check_Login() {
        # validate input
        if [ $(STRINGS_Is_Empty "$CONTAINER_USERNAME") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$CONTAINER_PASSWORD") -eq 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DOCKER_Clean_Up() {
        # validate input
        DOCKER_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        docker system prune --force
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DOCKER_Create() {
        ___destination="$1"
        ___os="$2"
        ___arch="$3"
        ___repo="$4"
        ___sku="$5"
        ___version="$6"


        # validate input
        if [ $(STRINGS_Is_Empty "${___destination}") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "${___os}") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "${___arch}") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "${___repo}") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "${___sku}") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "${___version}") -eq 0 ]; then
                return 1
        fi

        DOCKER_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        ___dockerfile="./Dockerfile"
        ___tag="$(DOCKER_Get_ID "$___repo" "$___sku" "$___version" "$___os" "$___arch")"

        FS_Is_File "$___dockerfile"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        DOCKER_Login "$___repo"
        if [ $? -ne 0 ]; then
                DOCKER_Logout
                return 1
        fi

        BUILDX_NO_DEFAULT_ATTESTATIONS=1 docker buildx build \
                --platform "${___os}/${___arch}" \
                --file "$___dockerfile" \
                --tag "$___tag" \
                --provenance=false \
                --sbom=false \
                --label "org.opencontainers.image.ref.name=${___tag}" \
                --push \
                .
        if [ $? -ne 0 ]; then
                DOCKER_Logout
                return 1
        fi

        DOCKER_Logout
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Append_File "$___destination" "${___os} ${___arch} ${___tag}\n"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DOCKER_Get_Builder_ID() {
        printf "multiarch"
}




DOCKER_Get_ID() {
        #___repo="$1"
        #___sku="$2"
        #___version="$3"
        #___os="$4"
        #___arch="$5"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$2") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$3") -eq 0 ]; then
                return 1
        fi


        # execute
        if [ $(STRINGS_Is_Empty "$4") -ne 0 ] && [ $(STRINGS_Is_Empty "$5") -ne 0 ]; then
                printf "$(STRINGS_To_Lowercase "${1}/${2}:${4}-${5}_${3}")"
        elif [ $(STRINGS_Is_Empty "$4") -eq 0 ] && [ $(STRINGS_Is_Empty "$5") -ne 0 ]; then
                printf "$(STRINGS_To_Lowercase "${1}/${2}:${5}_${3}")"
        elif [ $(STRINGS_Is_Empty "$4") -ne 0 ] && [ $(STRINGS_Is_Empty "$5") -eq 0 ]; then
                printf "$(STRINGS_To_Lowercase "${1}/${2}:${4}_${3}")"
        else
                printf "$(STRINGS_To_Lowercase "${1}/${2}:${3}")"
        fi


        # report status
        return 0
}




DOCKER_Is_Available() {
        # execute
        OS_Is_Command_Available "docker"
        if [ $? -ne 0 ]; then
                return 1
        fi

        docker ps &> /dev/null
        if [ $? -ne 0 ]; then
                return 1
        fi

        docker buildx inspect "$(DOCKER_Get_Builder_ID)" &> /dev/null
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DOCKER_Is_Valid() {
        #___target="$1"


        # execute
        FS_Is_File "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ "${1##*/}" = "docker.txt" ]; then
                return 0
        fi


        # report status
        return 1
}




DOCKER_Login() {
        #___repo="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        DOCKER_Check_Login
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        printf "$CONTAINER_PASSWORD" \
                | docker login "$1" \
                        --username "$CONTAINER_USERNAME" \
                        --password-stdin
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DOCKER_Logout() {
        # execute
        docker logout && rm -f "${HOME}/.docker/config.json" &> /dev/null
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DOCKER_Release() {
        ___target="$1"
        ___version="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$___target") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$___target"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___list=""
        ___repo=""
        ___sku=""
        ___old_IFS="$IFS"
        while IFS="" read -r ___line || [ -n "$___line" ]; do
                if [ $(STRINGS_Is_Empty "$___line") -eq 0 ] || [ "$___line" == "\n" ]; then
                        continue
                fi

                ___entry="${___line##* }"
                ___repo="${___entry%%:*}"
                ___sku="${___repo##*/}"
                ___repo="${___repo%/*}"

                if [ $(STRINGS_Is_Empty "$___list") -ne 0 ]; then
                        ___list="${___list} "
                fi

                ___list="${___list}--amend $___entry"
        done < "$___target"
        IFS="$___old_IFS" && unset ___old_IFS ___line

        if [ $(STRINGS_Is_Empty "$___list") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___repo") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___sku") -eq 0 ]; then
                return 1
        fi

        DOCKER_Login "$___repo"
        if [ $? -ne 0 ]; then
                DOCKER_Logout
                return 1
        fi

        DOCKER_Amend_Manifest "$(DOCKER_Get_ID "$___repo" "$___sku" "latest")" "$___list"
        if [ $? -ne 0 ]; then
                DOCKER_Logout
                return 1
        fi

        DOCKER_Amend_Manifest "$(DOCKER_Get_ID "$___repo" "$___sku" "$___version")" "$___list"
        if [ $? -ne 0 ]; then
                DOCKER_Logout
                return 1
        fi

        DOCKER_Logout
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DOCKER_Setup() {
        # validate input
        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        DOCKER_Is_Available
        if [ $? -ne 0 ]; then
                # NOTE: nothing else can be done since it's host-specific.
                #       DO NOT brew install Docker-Desktop autonomously.
                return 0
        fi


        # execute
        ___name="$(DOCKER_Get_Builder_ID)"

        docker buildx inspect "${___name}" &> /dev/null
        if [ $? -eq 0 ]; then
                return 0
        fi

        docker buildx create --use --name "${___name}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}

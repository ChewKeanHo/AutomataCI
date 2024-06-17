#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/io/net/http.sh"
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/archive/zip.sh"




NODE_Activate_Local_Environment() {
        # validate input
        NODE_Is_Localized
        if [ $? -eq 0 ]; then
                NODE_Is_Available
                if [ $? -ne 0 ]; then
                        return 1
                fi

                return 0
        fi


        # execute
        ___location="$(NODE_Get_Activator_Path)"
        FS_Is_File "$___location"
        if [ $? -ne 0 ]; then
                return 1
        fi

        . "$___location"
        NODE_Is_Localized
        if [ $? -ne 0 ]; then
                return 1
        fi

        NODE_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NODE_Get_Activator_Path() {
        printf -- "${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_NODE_ENGINE}/activate.sh"
}




NODE_Is_Available() {
        # execute
        if [ $(STRINGS_Is_Empty "$PROJECT_NODE_VERSION") -ne 0 ]; then
                ## check existing localized engine
                ___target="$(NODE_Get_Activator_Path)"
                FS_Is_File "$___target"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                ___target="$(FS_Get_Directory "$___target")"

                ## check localized node command availablity
                FS_Is_File "${___target}/bin/node"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                ## check localized npm command availablity
                FS_Is_File "${___target}/bin/npm"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                ## check localized npm command availablity
                FS_Is_File "${___target}/bin/npx"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                return 0
        fi

        OS_Is_Command_Available "npm"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "npx"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "node"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 1
}




NODE_Is_Localized() {
        # execute
        if [ $(STRINGS_Is_Empty "$PROJECT_NODE_LOCALIZED") -ne 0 ] ; then
                return 0
        fi


        # report status
        return 1
}




NODE_NPM_Check_Login() {
        # execute
        if [ $(STRINGS_Is_Empty "$PROJECT_NODE_NPM_REGISTRY") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$NPM_USERNAME") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$NPM_TOKEN") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_SCOPE") -eq 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NODE_NPM_Install_Dependencies_All() {
        # validate input
        NODE_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        npm install
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NODE_NPM_Is_Valid() {
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
        if [ $(FS_Is_Target_A_NPM "$1") -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NODE_NPM_Publish() {
        #___target="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        NODE_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/release-npm"
        ___package="${PROJECT_SKU}.tgz"
        ___npmrc=".npmrc"

        ## setup workspace
        FS_Remake_Directory "$___workspace"
        FS_Copy_File "$1" "${___workspace}/${___package}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ___current_path="$PWD" && cd "$___workspace"
        FS_Write_File "$___npmrc" "\
registry=${PROJECT_NODE_NPM_REGISTRY}
scope=@${PROJECT_SCOPE}
email=${NPM_USERNAME}
//${PROJECT_NODE_NPM_REGISTRY#*://}/:_authToken=${NPM_TOKEN}
"
        if [ $? -ne 0 ]; then
                FS_Remove_Silently "$___npmrc"
                return 1
        fi

        FS_Is_File "$___npmrc"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ## publish
        npm publish "$___package"
        ___process=$?
        FS_Remove_Silently "$___npmrc"
        cd "$___current_path" && unset ___current_path
        if [ $___process -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NODE_NPM_Run() {
        #___name="$1"


        # validate input
        NODE_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi


        # execute
        npm run "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NODE_Setup() {
        # validate input
        NODE_Is_Available
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        ___filepath=""
        case "$PROJECT_ARCH" in
        amd64)
                ___filepath="x64"
                ;;
        arm)
                ___filepath="armv7l"
                ;;
        arm64)
                ___filepath="arm64"
                ;;
        ppc64le)
                ___filepath="ppc64le"
                ;;
        s390x)
                ___filepath="s390x"
                ;;
        *)
                return 1
                ;;
        esac

        case "$PROJECT_OS" in
        aix)
                ___filepath="aix-${___filepath}.tar.xz"
                ;;
        darwin)
                ___filepath="darwin-${___filepath}.tar.xz"
                ;;
        windows)
                ___filepath="win-${___filepath}.zip"
                ;;
        linux)
                ___filepath="linux-${___filepath}.tar.xz"
                ;;
        *)
                return 1
                ;;
        esac

        ## download engine
        ___filepath="node-${PROJECT_NODE_VERSION}-${___filepath}"
        ___url="https://nodejs.org/dist/${PROJECT_NODE_VERSION}/${___filepath}"
        ___filepath="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${___filepath}"

        FS_Make_Housing_Directory "$___filepath"
        FS_Remove_Silently "$___filepath"
        HTTP_Download "GET" "$___url" "$___filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ## unpack engine
        FS_Is_File "$___filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ___location="$(NODE_Get_Activator_Path)"
        FS_Remove_Silently "$(FS_Get_Directory "$___location")"

        ___target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/"
        FS_Make_Directory "$___target"
        case "$PROJECT_OS" in
        windows)
                ZIP_Extract "$___target" "$___filepath"
                ___process=$?
                FS_Remove_Silently "$___filepath"
                ___target="$(FS_Extension_Replace "$___filepath" ".zip" "")"
                ;;
        *)
                TAR_Extract_XZ "$___target" "$___filepath"
                ___process=$?
                FS_Remove_Silently "$___filepath"
                ___target="$(FS_Extension_Replace "$___filepath" ".tar.xz" "")"
                ;;
        esac
        if [ $___process -ne 0 ]; then
                return 1
        fi

        ___directory="$(FS_Get_Directory "$___location")"
        FS_Move "$___target" "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi


        ## create activator script
        ___label="($PROJECT_PATH_NODE_ENGINE)"
        ___target="${___directory}/bin"
        FS_Write_File "$___location" "\
#!/bin/sh
___target=\"${___target}\"


deactivate() {
        ___path=:\$PATH:
        ___path=\${___path/:\$___target:/:}
        ___path=\${___path%:}
        ___path=\${___path#:}
        PATH=\$___path

        export PS1=\"\${PS1##*${___label} }\"
        unset PROJECT_NODE_LOCALIZED
        return 0
}




# check
if [ ! -z \"\$PROJECT_NODE_LOCALIZED\" ]; then
        return 0
fi




# activate
export PATH=\"\${___target}:\${PATH}\"

export PROJECT_NODE_LOCALIZED='${___location}'
export PS1=\"${___label} \${PS1}\"
return 0
"
        FS_Is_File "$___location"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ## test activator script
        NODE_Activate_Local_Environment
        if [ $? -ne 0 ] ; then
                return 1
        fi


        # report status
        return 0
}

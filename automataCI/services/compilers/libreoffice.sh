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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/net/http.sh"
. "${LIBS_AUTOMATACI}/services/compilers/msi.sh"
. "${LIBS_AUTOMATACI}/services/publishers/apple.sh"




LIBREOFFICE_Get() {
        # execute
        ___source="libreoffice"
        OS_Is_Command_Available "$___source"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$___source"
                return 0
        fi

        ___source="soffice"
        OS_Is_Command_Available "$___source"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$___source"
                return 0
        fi

        OS_Is_Command_Available "flatpak"
        if [ $? -eq 0 ]; then
                flatpak info org.libreoffice.LibreOffice &> /dev/null
                if [ $? -eq 0 ]; then
                        printf -- "%b" "flatpak run org.libreoffice.LibreOffice"
                        return 0
                fi
        fi

        ___source="$(LIBREOFFICE_Get_Path)"
        FS_Is_File "$___source"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$___source"
                return 0
        fi


        # report status
        return 1
}




LIBREOFFICE_Get_Path_Local() {
        # execute
        ___path="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_LIBREOFFICE_ENGINE}/bin/soffice"

        case "$PROJECT_OS" in
        windows)
                ___path="${___path}.exe"
                ;;
        *)
                ;;
        esac


        # report status
        printf -- "%b" "$___path"
        return 0
}




LIBREOFFICE_Get_Path() {
        # execute
        ___path="$(LIBREOFFICE_Get_Path_Local)"
        FS_Is_File "$___path"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$___path"
                return 0
        fi

        case "$PROJECT_OS" in
        darwin)
                ___path="/Applications/LibreOffice.app/Contents/MacOS/soffice"
                ;;
        windows)
                ___path="C:\\Program Files\\LibreOffice\\program\\soffice.exe"
                ;;
        *)
                ___path="/bin/soffice"
                ;;
        esac


        # report status
        printf -- "%b" "$___path"
        return 0
}




LIBREOFFICE_Is_Available() {
        # execute
        OS_Is_Command_Available "libreoffice"
        if [ $? -eq 0 ]; then
                return 0
        fi

        OS_Is_Command_Available "soffice"
        if [ $? -eq 0 ]; then
                return 0
        fi

        OS_Is_Command_Available "flatpak"
        if [ $? -eq 0 ]; then
                flatpak info org.libreoffice.LibreOffice &> /dev/null
                if [ $? -eq 0 ]; then
                        return 0
                fi
        fi

        FS_Is_File "$(LIBREOFFICE_Get_Path)"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




LIBREOFFICE_Setup() {
        # validate input
        LIBREOFFICE_Is_Available
        if [ $? -eq 0 ]; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_ROOT") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_PATH_TEMP") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_PATH_TOOLS") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_LIBREOFFICE_MIRROR") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_LIBREOFFICE_VERSION") -eq 0 ]; then
                return 1
        fi


        # execute
        ___dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_LIBREOFFICE_ENGINE}"
        ___url="${PROJECT_LIBREOFFICE_MIRROR}/stable/${PROJECT_LIBREOFFICE_VERSION}"
        case "$PROJECT_OS" in
        darwin)
                ___dest="${___dest}/install.dmg"

                ___url="${___url}/mac"
                case "$PROJECT_ARCH" in
                amd64)
                        ___url="${___url}/x86_64"
                        ___url="${___url}/LibreOffice_${PROJECT_LIBREOFFICE_VERSION}_MacOS_x86-64.dmg"
                        ;;
                arm64)
                        ___url="${___url}/aarch64"
                        ___url="${___url}/LibreOffice_${PROJECT_LIBREOFFICE_VERSION}_MacOS_aarch64.dmg"
                        ;;
                *)
                        ___url=""
                        ;;
                esac

                ## attempt to download from vendor directly
                if [ $(STRINGS_Is_Empty "$___url") -ne 0 ]; then
                        FS_Make_Housing_Directory "$___dest"
                        FS_Remove_Silently "$___dest"
                        HTTP_Download "GET" "$___url" "$___dest"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi

                        APPLE_Install_DMG "$___dest"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi

                        FS_Remove_Silently "$___dest"
                fi
                ;;
        windows)
                ___dest="${___dest}/install.msi"

                ___url="${___url}/win"
                case "$PROJECT_ARCH" in
                amd64)
                        ___url="${___url}/aarch64"
                        ___url="${___url}/LibreOffice_${PROJECT_LIBREOFFICE_VERSION}_Win_X86-64.msi"
                        ;;
                arm64)
                        ___url="${___url}/aarch64"
                        ___url="${___url}/LibreOffice_${PROJECT_LIBREOFFICE_VERSION}_Win_aarch64.msi"
                        ;;
                *)
                        ___url=""
                        ;;
                esac

                if [ $(STRINGS_Is_Empty "$___url") -ne 0 ]; then
                        FS_Make_Housing_Directory "$___dest"
                        FS_Remove_Silently "$___dest"
                        HTTP_Download "GET" "$___url" "$___dest"
                        ___process=$?
                        if [ $___process -eq 0 ]; then
                                MSI_Install_Silent "$___dest"
                                ___process=$?
                                FS_Remove_Silently "$___dest"
                        fi
                fi

                ## fallback to choco as the last resort
                if [ $(STRINGS_Is_Empty "$___url") -eq 0 ] || [ $___process -ne 0 ]; then
                        OS_Is_Command_Available "choco"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi

                        choco install libreoffice-fresh -y
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                fi
                ;;
        linux)
                OS_Is_Command_Available "flatpak"
                ___process=$?
                if [ $___process -eq 0 ]; then
                        flatpak --user install org.libreoffice.LibreOffice
                        ___process=$?
                fi

                ## download appimage as last resort
                if [ $___process -ne 0 ]; then
                        ___dest="$(LIBREOFFICE_Get_Path_Local)"
                        ___url="https://appimages.libreitalia.org"
                        case "$PROJECT_ARCH" in
                        amd64)
                                ___url="${___url}/LibreOffice-fresh.full-x86_64.AppImage"
                                ;;
                        *)
                                return 1
                                ;;
                        esac

                        if [ $(STRINGS_Is_Empty "$___url") -ne 0 ]; then
                                FS_Make_Housing_Directory "$___dest"
                                FS_Remove_Silently "$___dest"
                                HTTP_Download "GET" "$___url" "$___dest"
                                if [ $? -ne 0 ]; then
                                        return 1
                                fi

                                chmod +x "$___dest"
                                if [ $? -ne 0 ]; then
                                        return 1
                                fi
                        fi
                fi
                ;;
        *)
                return 1 # unsupported
                ;;
        esac


        # test the output
        LIBREOFFICE_Is_Available
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 0
}

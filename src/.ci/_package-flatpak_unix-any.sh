#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




PACKAGE_Assemble_FLATPAK_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate target before job
        case "$_target_arch" in
        avr)
                return 10 # not applicable
                ;;
        *)
                ;;
        esac

        if [ $(FS_Is_Target_A_Source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Docs "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Library "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_WASM_JS "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_WASM "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Chocolatey "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Homebrew "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Cargo "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_MSI "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_PDF "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ ! "$_target_os" = "linux" ] && [ ! "$_target_os" = "any" ]; then
                return 10 # not applicable
        fi


        # copy main program
        _target="$1"
        _filepath="${_directory}/${PROJECT_SKU}"
        I18N_Copy "$_target" "$_filepath"
        FS_Copy_File "$_target" "$_filepath"
        if [ $? -ne 0 ]; then
                I18N_Copy_Failed
                return 1
        fi


        # copy icon.svg
        _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/icons/icon.svg"
        _filepath="${_directory}/icon.svg"
        I18N_Copy "$_target" "$_filepath"
        FS_Copy_File "$_target" "$_filepath"
        if [ $? -ne 0 ]; then
                I18N_Copy_Failed
                return 1
        fi


        # copy icon-48x48.png
        _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/icons/icon-48x48.png"
        _filepath="${_directory}/icon-48x48.png"
        I18N_Copy "$_target" "$_filepath"
        FS_Copy_File "$_target" "$_filepath"
        if [ $? -ne 0 ]; then
                I18N_Copy_Failed
                return 1
        fi


        # copy icon-128x128.png
        _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/icons/icon-128x128.png"
        _filepath="${_directory}/icon-128x128.png"
        I18N_Copy "$_target" "$_filepath"
        FS_Copy_File "$_target" "$_filepath"
        if [ $? -ne 0 ]; then
                I18N_Copy_Failed
                return 1
        fi


        # [ COMPULSORY ] script manifest.yml
        __file="${_directory}/manifest.yml"
        I18N_Create "$__file"
        FS_Write_File "$__file" "\
app-id: ${PROJECT_APP_ID}
branch: ${_target_arch}
default-branch: any
command: ${PROJECT_SKU}
runtime: ${PROJECT_FLATPAK_RUNTIME}
runtime-version: '${PROJECT_FLATPAK_RUNTIME_VERSION}'
sdk: ${PROJECT_FLATPAK_SDK}
finish-args:
  - \"--share=network\"
  - \"--socket=pulseaudio\"
  - \"--filesystem=home\"
modules:
  - name: ${PROJECT_SKU}-main
    buildsystem: simple
    no-python-timestamp-fix: true
    build-commands:
      - install -D ${PROJECT_SKU} /app/bin/${PROJECT_SKU}
    sources:
      - type: file
        path: ${PROJECT_SKU}
  - name: ${PROJECT_SKU}-appdata
    buildsystem: simple
    build-commands:
      - install -D appdata.xml /app/share/metainfo/${PROJECT_APP_ID}.appdata.xml
    sources:
      - type: file
        path: appdata.xml
  - name: ${PROJECT_SKU}-icon-svg
    buildsystem: simple
    build-commands:
      - install -D icon.svg /app/share/icons/hicolor/scalable/apps/${PROJECT_SKU}.svg
    sources:
      - type: file
        path: icon.svg
  - name: ${PROJECT_SKU}-icon-48x48-png
    buildsystem: simple
    build-commands:
      - install -D icon-48x48.png /app/share/icons/hicolor/48x48/apps/${PROJECT_SKU}.png
    sources:
      - type: file
        path: icon-48x48.png
  - name: ${PROJECT_SKU}-icon-128x128-png
    buildsystem: simple
    build-commands:
      - install -D icon-128x128.png /app/share/icons/hicolor/128x128/apps/${PROJECT_SKU}.png
    sources:
      - type: file
        path: icon-128x128.png
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # [ COMPULSORY ] script appdata.xml
        __file="${_directory}/appdata.xml"
        I18N_Create "$__file"
        FS_Write_File "$__file" "\
<?xml version='1.0' encoding='UTF-8'?>
<!-- refer: https://www.freedesktop.org/software/appstream/docs/chap-Metadata.html -->
<component>
        <id>${PROJECT_APP_ID}</id>
        <name>${PROJECT_NAME}</name>
        <summary>${PROJECT_PITCH}</summary>
        <icon type='stock'>web-browser</icon>
        <metadata_license>CC0-1.0</metadata_license>
        <project_license>${PROJECT_LICENSE}</project_license>
        <categories>
                <!-- refer: https://specifications.freedesktop.org/menu-spec/latest/apa.html -->
                <category>Network</category>
                <category>Web</category>
        </categories>
        <keywords>
                <keyword>internet</keyword>
                <keyword>web</keyword>
                <keyword>browser</keyword>
        </keywords>
        <url type='homepage'>${PROJECT_CONTACT_WEBSITE}</url>
        <url type='contact'>${PROJECT_CONTACT_WEBSITE}</url>
        <screenshots>
                <screenshot type='default'>
                        <caption>Example Use</caption>
                        <image type='source' width='800' height='600'>
                                ${PROJECT_CONTACT_WEBSITE}/screenshot-800x600.png
                        </image>
                </screenshot>
        </screenshots>
        <provides>
                <binary>${PROJECT_SKU}</binary>
        </provides>
</component>
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # report status
        return 0
}

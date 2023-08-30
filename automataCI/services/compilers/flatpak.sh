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
FLATPAK::is_available() {
        __os="$1"
        __arch="$2"

        if [ -z "$__os" ] && [ -z "$__arch" ]; then
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
        if [ -z "$(type -t flatpak-builder)" ]; then
                return 1
        fi

        # report status
        return 0
}




FLATPAK::create_appinfo() {
        __directory="$1"
        __resources="$2"

        # validate input
        if [ -z "$__directory" ] ||
                [ -z "$__resources" ]; then
                unset __directory __resources
                return 1
        fi

        # check for overriding manifest file
        if [ -f "${__directory}/appdata.xml" ]; then
                unset __directory __resources
                return 2
        fi

        # check appinfo is available
        if [ ! -f "${__resources}/packages/flatpak.xml" ]; then
                unset __directory __resources
                return 1
        fi

        # copy flatpak.xml to workspace
        cp "${__resources}/packages/flatpak.xml" "${__directory}/appdata.xml"
        if [ $? -ne 0 ]; then
                unset __directory __resources
                return 1
        fi

        unset __directory __resources
        return 0
}




FLATPAK::create_manifest() {
        __location="$1"
        __resources="$2"
        __app_id="$3"
        __sku="$4"
        __arch="$5"
        __runtime="$6"
        __runtime_version="$7"
        __sdk="$8"

        # validate input
        if [ -z "$__location" ] ||
                [ -z "$__resources" ] ||
                [ -z "$__app_id" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__arch" ] ||
                [ -z "$__runtime" ] ||
                [ -z "$__runtime_version" ] ||
                [ -z "$__sdk" ] ||
                [ ! -d "$__resources" ] ||
                [ ! -d "$__location" ]; then
                unset __location \
                        __resources \
                        __app_id \
                        __sku \
                        __arch \
                        __runtime \
                        __runtime_version \
                        __sdk
                return 1
        fi

        # check for overriding manifest file
        if [ -f "${__location}/manifest.yml" ] || [ -f "${__location}/manifest.json" ]; then
                unset __location \
                        __resources \
                        __manifest \
                        __app_id \
                        __sku \
                        __arch \
                        __runtime \
                        __runtime_version \
                        __sdk
                return 2
        fi

        # generate manifest app metadata fields
        __location="${__location}/manifest.yml"
        printf "\
app-id: ${__app_id}
branch: ${__arch}
default-branch: any
command: ${__sku}
runtime: ${__runtime}
runtime-version: '${__runtime_version}'
sdk: ${__sdk}
modules:
  - name: ${__sku}-binary
    buildsystem: simple
    build-commands:
      - install -D ${__sku} /app/bin/${__sku}
    sources:
      - type: file
        path: ${__sku}
  - name: ${__sku}-appinfo
    buildsystem: simple
    build-commands:
      - install -D appdata.xml /app/share/metainfo/${__app_id}.appdata.xml
    sources:
      - type: file
        path: appdata.xml
" >> "$__location"

        # process icon.svg
        if [ -f "${1}/icon.svg" ]; then
                printf "\
  - name: ${__sku}-logo-svg
    buildsystem: simple
    build-commands:
      - install -D icon.svg /app/share/icons/hicolor/scalable/apps/${__sku}.svg
    sources:
      - type: file
        path: icon.svg
" >> "$__location"
        fi

        # process icon-48x48.png
        if [ -f "${1}/icon-48x48.png" ]; then
                printf "\
  - name: ${__sku}-logo-48x48-png
    buildsystem: simple
    build-commands:
      - install -D icon-48x48.png /app/share/icons/hicolor/48x48/apps/${__sku}.png
    sources:
      - type: file
        path: icon-48x48.png
" >> "$__location"
        fi

        # process icon-128x128.png
        if [ -f "${1}/icon-128x128.png" ]; then
                printf "\
  - name: ${__sku}-icon-128x128-png
    buildsystem: simple
    build-commands:
      - install -D icon-128x128.png /app/share/icons/hicolor/128x128/apps/${__sku}.png
    sources:
      - type: file
        path: icon-128x128.png
" >> "$__location"
        fi

        # append more setup if available
        if [ -f "${__resources}/packages/flatpak.yml" ]; then
                old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        __key="${__line%%:*}"
                        __key="${__key#"${__key%%[![:space:]]*}"}"
                        __key="${__key%"${__key##*[![:space:]]}"}"

                        if [ -z "$__line" ] || [ "$__key" = "modules" ]; then
                                continue
                        fi

                        printf "${__line}\n" >> "$__location"
                done < "${__resources}/packages/flatpak.yml"
                IFS="$old_IFS" && unset old_IFS
        fi

        # report status
        unset __location \
                __resources \
                __app_id \
                __sku \
                __arch \
                __runtime \
                __runtime_version \
                __sdk
        return 0
}




FLATPAK::create_archive() {
        __directory="$1"
        __destination="$2"
        __app_id="$3"
        __gpg_id="$4"

        # validate input
        if [ -z "$__directory" ] ||
                [ -z "$__destination" ] ||
                [ -z "$__app_id" ] ||
                [ -z "$__gpg_id" ] ||
                [ ! -d "$__directory" ]; then
                unset __directory \
                        __destination \
                        __app_id \
                        __gpg_id
                return 1
        fi

        # change location into the workspace
        __current_path="$PWD"
        cd "$__directory"

        __path_build="./build"
        __path_manifest="./manifest.yml"

        if [ ! -f "$__path_manifest" ]; then
                unset __directory \
                        __destination \
                        __app_id \
                        __gpg_id \
                        __path_build \
                        __path_manifest
                return 1
        fi

        # build archive
        flatpak-builder \
                --force-clean \
                --gpg-sign="${__gpg_id}" \
                "${__path_build}" \
                "${__path_manifest}"
        if [ $? -ne 0 ]; then
                cd "${__current_path}" && unset __current_path
                unset __directory \
                        __destination \
                        __app_id \
                        __gpg_id \
                        __path_build \
                        __path_manifest
                return 1
        fi

        # export output
        mv "$__path_build" "$__destination"
        if [ $? -ne 0 ]; then
                cd "${__current_path}" && unset __current_path
                unset __directory \
                        __destination \
                        __app_id \
                        __gpg_id \
                        __path_build \
                        __path_manifest
                return 1
        fi

        # head back to current directory
        cd "${__current_path}" && unset __current_path

        # report status
        return 0
}

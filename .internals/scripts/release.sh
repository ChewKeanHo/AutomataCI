#!/bin/bash
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




# determine PROJECT_PATH_PWD
export PROJECT_PATH_PWD="$PWD"
export PROJECT_PATH_AUTOMATA="automataCI"




# determine PROJECT_PATH_ROOT
if [ -f "./ci.sh" ]; then
        PROJECT_PATH_ROOT="${PWD%/*}/"
elif [ -f "./${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
        # current directory is the root directory.
        PROJECT_PATH_ROOT="$PWD"
else
        __pathing="$PROJECT_PATH_PWD"
        __previous=""
        while [ "$__pathing" != "" ]; do
                PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT}${__pathing%%/*}/"
                __pathing="${__pathing#*/}"
                if [ -f "${PROJECT_PATH_ROOT}${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
                        break
                fi

                # stop the scan if the previous pathing is the same as current
                if [ "$__previous" = "$__pathing" ]; then
                        1>&2 printf "[ ERROR ] [ ERROR ] Missing root directory.\n"
                        return 1
                fi
                __previous="$__pathing"
        done
        unset __pathing __previous
        export PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT%/*}"

        if [ ! -f "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
                1>&2 printf "[ ERROR ] [ ERROR ] Missing root directory.\n"
                exit 1
        fi
fi

export LIBS_AUTOMATACI="${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}"




# import fundamental libraries
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/compilers/libreoffice.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




# determine host system parameters
export PROJECT_OS="$(OS_Get)"
if [ "$(STRINGS_Is_Empty "$PROJECT_OS")" -eq 0 ]; then
        I18N_Unsupported_OS
        return 1
fi

export PROJECT_ARCH="$(OS_Get_Arch)"
if [ "$(STRINGS_Is_Empty "$PROJECT_ARCH")" -eq 0 ]; then
        I18N_Unsupported_ARCH
        return 1
fi




# parse repo CI configurations
if [ ! -f "${PROJECT_PATH_ROOT}/CONFIG.toml" ]; then
        I18N_Missing "CONFIG.toml"
        return 1
fi


__old_IFS="$IFS"
while IFS= read -r __line || [ -n "$__line" ]; do
        __line="${__line%%#*}"
        if [ "$(STRINGS_Is_Empty "$__line")" -eq 0 ]; then
                continue
        fi

        key="${__line%%=*}"
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        key="${key%\"}"
        key="${key#\"}"
        key="${key%\'}"
        key="${key#\'}"

        value="${__line##*=}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"

        export "$key"="$value"
done < "${PROJECT_PATH_ROOT}/CONFIG.toml"
IFS="$__old_IFS" && unset __old_IFS




# parse repo CI secret configurations
if [ -f "${PROJECT_PATH_ROOT}/SECRETS.toml" ]; then
        __old_IFS="$IFS"
        while IFS= read -r __line || [ -n "$__line" ]; do
                __line="${__line%%#*}"
                if [ "$(STRINGS_Is_Empty "$__line")" -eq 0 ]; then
                        continue
                fi

                key="${__line%%=*}"
                key="${key#"${key%%[![:space:]]*}"}"
                key="${key%"${key##*[![:space:]]}"}"
                key="${key%\"}"
                key="${key#\"}"
                key="${key%\'}"
                key="${key#\'}"

                value="${__line##*=}"
                value="${value#"${value%%[![:space:]]*}"}"
                value="${value%"${value##*[![:space:]]}"}"
                value="${value%\"}"
                value="${value#\"}"
                value="${value%\'}"
                value="${value#\'}"

                export "$key"="$value"
        done < "${PROJECT_PATH_ROOT}/SECRETS.toml"
        IFS="$__old_IFS" && unset __old_IFS
fi




# determine language
export AUTOMATACI_LANG="${AUTOMATACI_LANG:-$(OS_Get_Lang)}"
if [ "$(STRINGS_Is_Empty "$AUTOMATACI_LANG")" -eq 0 ]; then
        export AUTOMATACI_LANG="en" # fall back to english
fi




# update environment variable
OS_Sync
cd "$PROJECT_PATH_ROOT"




# clean up harsh data
FS_Remove_Silently "srcANGULAR/node_modules"
FS_Remove_Silently "srcANGULAR/.angular"




# execute command
___directory="pkg"
FS_Make_Directory "$___directory"


__old_IFS="$IFS"
while IFS="" read -r __line || [ -n "$__line" ]; do
        if [ $(STRINGS_Is_Empty "$__line") -eq 0 ]; then
                continue
        fi


        # build the file
        if [ "$__line" = "${PROJECT_PATH_AUTOMATA}" ]; then
                ___dest="${___directory}/${PROJECT_SKU}-core_${PROJECT_VERSION}.tar.gz"
                I18N_Export "$___dest"
                FS_Remove_Silently "$___dest"
                tar czf "$___dest" \
                        -C "$PROJECT_PATH_ROOT" "$__line" \
                        -C "$PROJECT_PATH_ROOT" "CONFIG.toml" \
                        -C "$PROJECT_PATH_ROOT" ".gitignore" &> /dev/null
        elif [ "$__line" = "src" ]; then
                # move the changelog away first
                ___changelog_temp="${PROJECT_PATH_ROOT}/.changelog"
                ___changelog_real="${PROJECT_PATH_ROOT}/src/changelog/"
                FS_Move "$___changelog_real" "$___changelog_temp"
                FS_Make_Directory "$___changelog_real"
                sync

                ___dest="${___directory}/${PROJECT_SKU}-${__line}_${PROJECT_VERSION}.tar.gz"
                I18N_Export "$___dest"
                FS_Remove_Silently "$___dest"
                tar czf "$___dest" -C "$PROJECT_PATH_ROOT" "$__line" &> /dev/null


                # restore the changelog back
                FS_Remove_Silently "$___changelog_real"
                FS_Move "$___changelog_temp" "$___changelog_real"
                sync
        else
                ___dest="${___directory}/${PROJECT_SKU}-${__line}_${PROJECT_VERSION}.tar.gz"
                I18N_Export "$___dest"
                FS_Remove_Silently "$___dest"
                tar czf "$___dest" -C "$PROJECT_PATH_ROOT" "$__line" &> /dev/null
        fi
done <<EOF
${PROJECT_PATH_AUTOMATA}
src
srcC
srcNIM
srcRUST
srcGO
srcPYTHON
srcANGULAR
EOF
IFS="$__old_IFS" && unset __old_IFS


# copy official documents
__old_IFS="$IFS"
find ".internals/docs" -maxdepth 1 -name '*.odt' -printf "%p\n" \
        | while IFS= read -r ___file_src || [ -n "$___file_src" ]; do
        if [ $(STRINGS_Is_Empty "$___file_src") -eq 0 ]; then
                continue
        fi

        ## apply filter
        case "$(FS_Get_File "$___file_src")" in
        *)
                ;;
        esac


        ## build the pdf document
        I18N_Build "$___file_src"
        $(LIBREOFFICE_Get) --headless --convert-to "pdf:writer_pdf_Export:{
        \"UseLosslessCompression\": true,
        \"Quality\": 100,
        \"SelectPdfVersion\": 0,
        \"PDFUACompliance\": false,
        \"UseTaggedPDF\": true,
        \"ExportFormFields\": true,
        \"FormsType\": 1,
        \"ExportBookmarks\": true,
        \"ExportPlaceholders\": true
}" --outdir "$___directory" "$___file_src"
        if [ $? -ne 0 ]; then
                I18N_Build_Failed
                exit 1
        fi

        ## obtain language code
        ___src="${___file_src##*/}"
        ___src="$(FS_Extension_Remove "$___src" "*")"

        ## construct destination
        case "$___src" in
        de)
                ___dest="${PROJECT_SKU}-bedienungsanleitung_${PROJECT_VERSION}_de.pdf"
                ;;
        en)
                ___dest="${PROJECT_SKU}-user-guide_${PROJECT_VERSION}_en.pdf"
                ;;
        es)
                ___dest="${PROJECT_SKU}-manual-de-usuario_${PROJECT_VERSION}_es.pdf"
                ;;
        fr)
                ___dest="${PROJECT_SKU}-manuel-dutilisation_${PROJECT_VERSION}_fr.pdf"
                ;;
        jp)
                ___dest="${PROJECT_SKU}-ユーザーガイド_${PROJECT_VERSION}_jp.pdf"
                ;;
        ko)
                ___dest="${PROJECT_SKU}-사용자안내_${PROJECT_VERSION}_ko.pdf"
                ;;
        mn)
                ___dest="${PROJECT_SKU}-xэрэглэгчийн-удирдамж_${PROJECT_VERSION}_mn.pdf"
                ;;
        nb)
                ___dest="${PROJECT_SKU}-brukerveiledning_${PROJECT_VERSION}_nb.pdf"
                ;;
        nl)
                ___dest="${PROJECT_SKU}-gebruiksaanwijzing_${PROJECT_VERSION}_nl.pdf"
                ;;
        nn)
                ___dest="${PROJECT_SKU}-brukarrettleiding_${PROJECT_VERSION}_nn.pdf"
                ;;
        ru)
                ___dest="${PROJECT_SKU}-pуководство-пользователя_${PROJECT_VERSION}_ru.pdf"
                ;;
        sv)
                ___dest="${PROJECT_SKU}-användarhandbok_${PROJECT_VERSION}_sv.pdf"
                ;;
        uk)
                ___dest="${PROJECT_SKU}-користувацький-посібник_${PROJECT_VERSION}_uk.pdf"
                ;;
        zh-hans)
                ___dest="${PROJECT_SKU}-说明指南_${PROJECT_VERSION}_zh-hans.pdf"
                ;;
        zh-hant)
                ___dest="${PROJECT_SKU}-說明指南_${PROJECT_VERSION}_zh-hant.pdf"
                ;;
        *)
                continue # unknown - bail out
                ;;
        esac

        ## export to correct name
        I18N_Export "${___directory}/${___dest}"
        FS_Move "${___directory}/${___src}.pdf" "${___directory}/${___dest}"
        if [ $? -ne 0 ]; then
                I18N_Export_Failed
                exit 1
        fi
done
IFS="$__old_IFS" && unset __old_IFS




# report status
I18N_Run_Successful
exit 0

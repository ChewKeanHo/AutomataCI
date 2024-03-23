#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/compilers/libreoffice.sh"




# execute
I18N_Activate_Environment
LIBREOFFICE_Is_Available
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi


FS_Make_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"


___target="research-paper"
___source="${PROJECT_PATH_ROOT}/${PROJECT_RESEARCH}/${___target}.odt"
___dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/research-${PROJECT_SKU}_any-any"
I18N_Prepare "$___source"
FS_Is_File "$___source"
if [ $? -ne 0 ]; then
        I18N_Prepare_Failed
        return 1
fi

FS_Remake_Directory "$___dest"




## build pdf - refer the following page for modifying parameters:
#    https://help.libreoffice.org/latest/en-US/text/shared/guide/pdf_params.html
I18N_Build "$___source"
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
}" --outdir "$___dest" "$___source"
___process=$?
if [ $___process -ne 0 ]; then
        I18N_Build_Failed
        return 1
fi




## export outputs
___source="${___dest}/${___target}.pdf"
___dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${PROJECT_SKU}-research_${PROJECT_VERSION}_any-any.pdf"

FS_Is_File "$___source"
if [ $? -ne 0 ]; then
        I18N_Build_Failed
        return 1
fi

I18N_Export "$___dest"
FS_Remove_Silently "$___dest"
FS_Copy_File "$___source" "$___dest"
if [ $? -ne 0 ]; then
        I18N_Export_Failed
        return 1
fi




# report status
return 0

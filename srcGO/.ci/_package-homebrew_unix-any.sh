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




PACKAGE_Assemble_HOMEBREW_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate project
        if [ $(FS_Is_Target_A_Homebrew "$_target") -ne 0 ]; then
                return 10 # not applicable
        fi


        # assemble the package
        ___source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/"
        ___dest="${_directory}/${PROJECT_PATH_SOURCE}"
        I18N_Assemble "$___source" "$___dest"
        FS_Make_Directory "$___dest"
        FS_Copy_All "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/.ci/"
        ___dest="${_directory}/${PROJECT_PATH_SOURCE}/.ci"
        I18N_Assemble "$___source" "$___dest"
        FS_Make_Directory "$___dest"
        FS_Copy_All "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/${PROJECT_GO}/"
        ___dest="${_directory}/${PROJECT_GO}"
        I18N_Assemble "$___source" "$___dest"
        FS_Make_Directory "$___dest"
        FS_Copy_All "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/${PROJECT_GO}/.ci/"
        ___dest="${_directory}/${PROJECT_GO}/.ci"
        I18N_Assemble "$___source" "$___dest"
        FS_Make_Directory "$___dest"
        FS_Copy_All "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/automataCI/"
        ___dest="${_directory}/automataCI"
        I18N_Assemble "$___source" "$___dest"
        FS_Make_Directory "$___dest"
        FS_Copy_All "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/CONFIG.toml"
        ___dest="$_directory"
        I18N_Assemble "$___source" "$___dest"
        FS_Make_Directory "$___dest"
        FS_Copy_File "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi


        # script formula.rb
        ___dest="${_directory}/formula.rb"
        I18N_Create "$___dest"
        FS_Write_File "$___dest" "\
class $(STRINGS_To_Titlecase "$PROJECT_SKU") < Formula
  desc \"${PROJECT_PITCH}\"
  homepage \"${PROJECT_CONTACT_WEBSITE}\"
  license \"${PROJECT_LICENSE}\"
  url \"${PROJECT_HOMEBREW_SOURCE_URL}/{{ TARGET_PACKAGE }}\"
  sha256 \"{{ TARGET_SHASUM }}\"

  depends_on \"go\" => [:build, :test]

  def install
    system \"./automataCI/ci.sh.ps1 setup\"
    system \"./automataCI/ci.sh.ps1 prepare\"
    system \"./automataCI/ci.sh.ps1 materialize\"
    chmod 0755, \"bin/${PROJECT_SKU}\"
    libexec.install \"bin/${PROJECT_SKU}\"
    bin.install_symlink libexec/\"${PROJECT_SKU}\" => \"${PROJECT_SKU}\"
  end

  test do
    system \"./automataCI/ci.sh.ps1 setup\"
    system \"./automataCI/ci.sh.ps1 prepare\"
    system \"./automataCI/ci.sh.ps1 materialize\"
    assert_predicate ./bin/${PROJECT_SKU}, :exist?
  end
end
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # report status
        return 0
}

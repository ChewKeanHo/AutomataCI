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




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/strings.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/rust.sh"




PACKAGE::assemble_homebrew_content() {
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
        FS_Make_Directory "${_directory}/${PROJECT_PATH_SOURCE}"
        FS_Copy_All "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/" \
                        "${_directory}/${PROJECT_PATH_SOURCE}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Make_Directory "${_directory}/${PROJECT_PATH_SOURCE}/.ci"
        FS_Copy_All "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/.ci/" \
                        "${_directory}/${PROJECT_PATH_SOURCE}/.ci"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Make_Directory "${_directory}/${PROJECT_RUST}"
        FS_Copy_All "${PROJECT_PATH_ROOT}/${PROJECT_RUST}/" "${_directory}/${PROJECT_RUST}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Make_Directory "${_directory}/${PROJECT_RUST}/.ci"
        FS_Copy_All "${PROJECT_PATH_ROOT}/${PROJECT_RUST}/.ci/" \
                        "${_directory}/${PROJECT_RUST}/.ci"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Copy_All "${PROJECT_PATH_ROOT}/automataCI" "$_directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Copy_File "${PROJECT_PATH_ROOT}/CONFIG.toml" "$_directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RUST_Create_CARGO_TOML \
                "${_directory}/${PROJECT_RUST}/Cargo.toml" \
                "${PROJECT_PATH_ROOT}/${PROJECT_RUST}/Cargo.toml" \
                "$PROJECT_SKU" \
                "$PROJECT_VERSION" \
                "$PROJECT_PITCH" \
                "$PROJECT_RUST_EDITION" \
                "$PROJECT_LICENSE" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_SOURCE_URL" \
                "README.md" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # script formula.rb
        OS_Print_Status info "scripting formula.rb...\n"
        FS_Write_File "${_directory}/formula.rb" "\
class ${PROJECT_SKU_TITLECASE} < Formula
  desc \"${PROJECT_PITCH}\"
  homepage \"${PROJECT_CONTACT_WEBSITE}\"
  license \"${PROJECT_LICENSE}\"
  url \"${PROJECT_HOMEBREW_SOURCE_URL}/${PROJECT_VERSION}/{{ TARGET_PACKAGE }}\"
  sha256 \"{{ TARGET_SHASUM }}\"


  def install
    system \"./automataCI/ci.sh.ps1 setup\"
    system \"./automataCI/ci.sh.ps1 prepare\"
    system \"./automataCI/ci.sh.ps1 materialize\"
    chmod 0755, \"bin/${PROJECT_SKU}\"
    bin.install \"bin/${PROJECT_SKU}\"
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
                return 1
        fi


        # report status
        return 0
}

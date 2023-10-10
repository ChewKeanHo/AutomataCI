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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/python.sh"




PACKAGE::assemble_homebrew_content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate project
        if [ $(FS::is_target_a_source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_library "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_wasm_js "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_wasm "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_chocolatey "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_homebrew "$_target") -eq 0 ]; then
                : # accepted
        else
                return 10 # not applicable
        fi


        # assemble the package
        FS::make_directory "${_directory}/Data/${PROJECT_PATH_SOURCE}"
        FS::copy_all "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/" \
                        "${_directory}/Data/${PROJECT_PATH_SOURCE}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        PYTHON::clean_artifact "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}"
        FS::copy_all "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}" "${_directory}/Data"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::copy_all "${PROJECT_PATH_ROOT}/automataCI" "${_directory}/Data"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::copy_file "${PROJECT_PATH_ROOT}/CONFIG.toml" "${_directory}/Data"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::copy_file "${PROJECT_PATH_ROOT}/ci.cmd" "${_directory}/Data"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # script formula.rb
        OS::print_status info "scripting formula.rb...\n"
        FS::write_file "${_directory}/formula.rb" "\
class ${PROJECT_SKU_TITLECASE} < Formula
  desc \"${PROJECT_PITCH}\"
  homepage \"${PROJECT_CONTACT_WEBSITE}\"
  license \"${PROJECT_LICENSE}\"
  url \"${PROJECT_HOMEBREW_SOURCE_URL}/${PROJECT_VERSION}/{{ TARGET_PACKAGE }}\"
  sha256 \"{{ TARGET_SHASUM }}\"


  depends_on \"go\" => [:build, :test]

  def install
    system \"./ci.cmd setup\"
    system \"./ci.cmd prepare\"
    system \"./ci.cmd materialize\"
    chmod 0755, \"bin/${PROJECT_SKU}\"
    bin.install \"bin/${PROJECT_SKU}\"
  end

  test do
    system \"./ci.cmd setup\"
    system \"./ci.cmd prepare\"
    system \"./ci.cmd materialize\"
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

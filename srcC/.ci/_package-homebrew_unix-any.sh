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




PACKAGE::assemble_homebrew_content() {
        __target="$1"
        __directory="$2"
        __target_name="$3"
        __target_os="$4"
        __target_arch="$5"


        # validate project
        if [ $(FS::is_target_a_source "$__target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_library "$__target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_wasm_js "$__target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_wasm "$__target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_homebrew "$__target") -eq 0 ]; then
                : # accepted
        else
                return 10 # not applicable
        fi


        # assemble the package
        FS::make_directory "${__directory}/Data/${PROJECT_PATH_SOURCE}"
        FS::copy_all "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/" \
                        "${__directory}/Data/${PROJECT_PATH_SOURCE}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::copy_all "${PROJECT_PATH_ROOT}/${PROJECT_C}" "${__directory}/Data"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::copy_all "${PROJECT_PATH_ROOT}/automataCI" "${__directory}/Data"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::copy_file "${PROJECT_PATH_ROOT}/CONFIG.toml" "${__directory}/Data"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::copy_file "${PROJECT_PATH_ROOT}/ci.cmd" "${__directory}/Data"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # script formula.rb
        OS::print_status info "scripting formula.rb...\n"
        FS::write_file "${__directory}/formula.rb" "\
class ${PROJECT_SKU_TITLECASE} < Formula
  desc \"${PROJECT_PITCH}\"
  homepage \"${PROJECT_CONTACT_WEBSITE}\"
  license \"${PROJECT_LICENSE}\"
  url \"${PROJECT_HOMEBREW_SOURCE_URL}/${PROJECT_VERSION}/{{ TARGET_PACKAGE }}\"
  sha256 \"{{ TARGET_SHASUM }}\"

  on_linux do
    depends_on \"gcc\" => [:build, :test]
  end

  on_macos do
    depends_on \"clang\" => [:build, :test]
  end

  def install
    system \"./ci.cmd setup\"
    system \"./ci.cmd prepare\"
    system \"./ci.cmd materialize\"
    chmod 0755, \"bin/${PROJECT_SKU}\"
    bin.install \"bin/${PROJECT_SKU}\"
    libexec.install Dir[\"lib/*\"]
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

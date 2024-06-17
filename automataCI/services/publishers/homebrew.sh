#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/checksum/shasum.sh"




HOMEBREW_Is_Valid_Formula() {
        #___target="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        if [ ! "${1%.asc*}" = "$1" ]; then
                return 1
        fi


        # execute
        if [ ! "${1%.rb*}" = "$1" ]; then
                return 0
        fi


        # report status
        return 1
}




HOMEBREW_Seal() {
        ___formula="$1"
        ___archive_name="$2"
        ___workspace="$3"
        ___sku="$4"
        ___description="$5"
        ___website="$6"
        ___license="$7"
        ___base_url="$8"


        # validate input
        if [ $(STRINGS_Is_Empty "$___formula") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___archive_name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___workspace") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___sku") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___description") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___website") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___license") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___base_url") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___workspace"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ___export_directory="$(FS_Get_Directory "$___formula")"
        if [ "$___export_directory" = "$___formula" ]; then
                return 1
        fi
        FS_Make_Directory "$___export_directory"


        # execute
        ## generate the init script
        ___dest="${___workspace}/init.sh"
        FS_Write_File "$___dest" "\
#!/bin/sh
OS_Get_Arch() {
        ___output=\"\$(uname -m)\"
        ___output=\"\$(printf -- \"%b\" \"\$___output\" | tr '[:upper:]' '[:lower:]')\"
        case \"\$___output\" in
        i686-64)
                export ___output='ia64' # Intel Itanium.
                ;;
        i386|i486|i586|i686)
                export ___output='i386'
                ;;
        x86_64)
                export ___output='amd64'
                ;;
        sun4u)
                export ___output='sparc'
                ;;
        'power macintosh')
                export ___output='powerpc'
                ;;
        ip*)
                export ___output='mips'
                ;;
        *)
                ;;
        esac


        # report status
        printf -- \"%b\" \"\$___output\"
        return 0
}


OS_Get() {
        # execute
        ___output=\"\$(uname)\"
        ___output=\"\$(printf -- \"%b\" \"\${___output}\" | tr '[:upper:]' '[:lower:]')\"
        case \"\$___output\" in
        windows*|ms-dos*)
                ___output='windows'
                ;;
        cygwin*|mingw*|mingw32*|msys*)
                ___output='windows'
                ;;
        *freebsd)
                ___output='freebsd'
                ;;
        dragonfly*)
                ___output='dragonfly'
                ;;
        *)
                ;;
        esac


        # report status
        printf -- \"%b\" \"\$___output\"
        return 0
}


main() {
        host_os=\"\$(OS_Get)\"
        host_arch=\"\$(OS_Get_Arch)\"
        for ___file in './bin/'*; do
                if [ ! -e \"\$___file\" ]; then
                        continue
                fi

                ___system=\"\${___file##*/}\"
                ___system=\"\${___system%%.*}\"
                ___system=\"\${___system##*_}\"
                ___os=\"\${___system%%-*}\"
                ___arch=\"\${___system##*-}\"

                case \"\$___os\" in
                any|\"\$host_os\")
                        ;;
                *)
                        rm -f \"\$___file\" &> /dev/null
                        continue
                        ;;
                esac

                case \"\$___arch\" in
                any|\"\$host_arch\")
                        mv \"\$___file\" \"\${___file%%_*}\"
                        ;;
                *)
                        rm -f \"\$___file\" &> /dev/null
                        ;;
                esac
        done

        return 0
}
main \$*
return \$?
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ## seal the workspace
        ___current_path="$PWD" && cd "$___workspace"
        TAR_Create_XZ "${___export_directory}/${___archive_name}" "."
        ___process=$?
        cd "$___current_path" && unset ___current_path
        if [ $___process -ne 0 ]; then
                return 1
        fi

        ## create the formula
        ___shasum="$(SHASUM_Create_From_File "${___export_directory}/${___archive_name}" "256")"
        if [ $(STRINGS_Is_Empty "$___shasum") -eq 0 ]; then
                return 1
        fi

        FS_Make_Housing_Directory "$___formula"
        FS_Write_File "$___formula" "\
class $(STRINGS_To_Titlecase "$___sku") < Formula
  desc '${___description}'
  homepage '${___website}'
  license '${___license}'
  url '${___base_url}/${___archive_name}'
  sha256 '${___shasum}'

  def install
    if File.file?('init.sh.ps1')
      chmod 755, './init.sh.ps1'
      system './init.sh.ps1'
    else
      chmod 755, './init.sh'
      system './init.sh'
    end

    if File.directory?('bin')
      Dir.foreach('bin') do |filename|
        next if filename == '.' or filename == '..'
        chmod 0755, filename
        libexec.install 'bin/' + filename
        bin.install_symlink 'libexec/bin/' + filename => filename
      end
    end

    if File.directory?('lib')
      Dir.foreach('lib') do |filename|
        next if filename == '.' or filename == '..'
        chmod 0544, filename
        libexec.install 'lib/' + filename
        lib.install_symlink 'libexec/lib/' + filename => filename
      end
    end
  end

  test do
    if File.file?('init.sh.ps1')
      assert_predicate 'init.sh.ps1', :exist?
    else
      assert_predicate 'init.sh', :exist?
    end
  end
end
"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




HOMEBREW_Setup() {
        # validate input
        OS_Is_Command_Available "curl"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "brew"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ $? -ne 0 ]; then
                return 1
        fi

        case "$PROJECT_OS" in
        linux)
                ___location="/home/linuxbrew/.linuxbrew/bin/brew"
                ;;
        darwin)
                ___location="/usr/local/bin/brew"
                ;;
        *)
                return 1
                ;;
        esac

        ___old_IFS="$IFS"
        while IFS= read -r ___line || [ -n "$___line" ]; do
                if [ "$___line" = "eval \"\$(${___location} shellenv)\"" ]; then
                        unset ___location
                        break
                fi
        done < "${HOME}/.bash_profile"

        printf -- "eval \"\$(${___location} shellenv)\"" >> "${HOME}/.bash_profile"
        if [ $? -ne 0 ]; then
                return 1
        fi
        eval "$(${___location} shellenv)"

        OS_Is_Command_Available "brew"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}

# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\checksum\shasum.ps1"




function HOMEBREW-Is-Valid-Formula {
	param (
		[string]$___target
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___target}") -eq 0) {
		return 1
	}

	if ($___target -like "*.asc") {
		return 1
	}


	# execute
	if ($___target -like "*.rb") {
		return 1
	}


	# report status
	return 1
}




function HOMEBREW-Seal {
	param (
		[string]$___formula,
		[string]$___archive_name,
		[string]$___workspace,
		[string]$___sku,
		[string]$___description,
		[string]$___website,
		[string]$___license,
		[string]$___base_url
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___formula}") -eq 0) -or
		($(STRINGS-Is-Empty "${___archive_name}") -eq 0) -or
		($(STRINGS-Is-Empty "${___workspace}") -eq 0) -or
		($(STRINGS-Is-Empty "${___sku}") -eq 0) -or
		($(STRINGS-Is-Empty "${___description}") -eq 0) -or
		($(STRINGS-Is-Empty "${___website}") -eq 0) -or
		($(STRINGS-Is-Empty "${___license}") -eq 0) -or
		($(STRINGS-Is-Empty "${___base_url}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___workspace}"
	if ($___process -ne 0) {
		return 1
	}

	$___export_directory = "$(FS-Get-Directory "${___formula}")"
	if ($___export_directory -eq $___formula) {
		return 1
	}
	$null = FS-Make-Directory "${___export_directory}"


	# execute
	## generate the init script
	$___dest = "${___workspace}/init.sh"
	$___process = FS-Write-File "${___dest}" @"
#!/bin/sh
OS_Get_Arch() {
        ___output="`$(uname -m)"
        ___output="`$(printf -- "%b" "`$___output" | tr '[:upper:]' '[:lower:]')"
        case "`$___output" in
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
        printf -- "%b" "`$___output"
        return 0
}


OS_Get() {
        # execute
        ___output="`$(uname)"
        ___output="`$(printf -- "%b" "`${___output}" | tr '[:upper:]' '[:lower:]')"
        case "`$___output" in
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
        printf -- "%b" "`$___output"
        return 0
}


main() {
        host_os="`$(OS_Get)"
        host_arch="`$(OS_Get_Arch)"
        for ___file in './bin/'*; do
                if [ ! -e "`$___file" ]; then
                        continue
                fi

                ___system="`${___file##*/}"
                ___system="`${___system%%.*}"
                ___system="`${___system##*_}"
                ___os="`${___system%%-*}"
                ___arch="`${___system##*-}"

                case "`$___os" in
                any|"`$host_os")
                        ;;
                *)
                        rm -f "`$___file" &> /dev/null
                        continue
                        ;;
                esac

                case "`$___arch" in
                any|"`$host_arch")
                        mv "`$___file" "`${___file%%_*}"
                        ;;
                *)
                        rm -f "`$___file" &> /dev/null
                        ;;
                esac
        done

        return 0
}
main `$*
return `$?

"@
	if ($___process -ne 0) {
		return 1
	}

	## seal the workspace
	$___current_path = Get-Location
	$null = Set-Location -Path "${___workspace}"
	$___process = TAR-Create-XZ "${___export_directory}\${___archive_name}" "."
	$null = Set-Location -Path "${___current_path}"
	$null = Remove-Variable -Name ___current_path
	if ($___process -ne 0) {
		return 1
	}

	## create the formula
	$___shasum = SHASUM-Create-From-File "${___export_directory}/${___archive_name}" "256"
	if ($(STRINGS-Is-Empty "${___shasum}") -eq 0) {
		return 1
	}

        $null = FS-Make-Housing-Directory "${___formula}"
        $___process = FS-Write-File "${___formula}" @"
class $(STRINGS-To-Titlecase "${___sku}") < Formula
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

"@
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function HOMEBREW-Setup {
	# report status
	return 1 # unsupported
}

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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/sync.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/c.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/nim.sh"




BUILD::__exec_compile_source_code() {
        # execute
        OS::print_status info "executing ${@}\n"
        $@
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n\n"
                return 1
        fi


        # report status
        return 0
}




BUILD::__validate_config_file() {
        #_target_config="$1"
        #_target_source="$2"


        # execute
        FS::is_file "${PROJECT_PATH_ROOT}/${2}/${1}"
        if [ $? -eq 0 ]; then
                printf -- "%b" "${PROJECT_PATH_ROOT}/${2}/${1}"
                return 0
        elif [ ! "${1#*${PROJECT_PATH_ROOT}}" = "$1" ]; then
                printf -- "%b" "$1"
                return 0
        fi


        # report status
        printf -- ""
        return 1
}




BUILD::__validate_source_files() {
        _target_config="$1"
        _target_source="$2"
        _target_compiler="$3"
        _target_args="$4"
        _target_directory="$5"
        _linker_control="$6"
        _target_os="$7"
        _target_arch="$8"


        # execute
        _parallel_total=0
        __old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                __line="${__line%%#*}"
                if [ -z "$__line" ]; then
                        continue
                fi


                # check source code existence
                __path="${PROJECT_PATH_ROOT}/${_target_source}/${__line##* }"
                OS::print_status info "validating source file: ${__path}\n"
                FS::is_file "${__path}"
                if [ $? -ne 0 ]; then
                        OS::print_status error "validation failed.\n\n"
                        return 1
                fi


                # check source code compatibilities
                __os="${__line%% *}"
                __arch="${__os##*-}"
                __os="${__os%%-*}"

                if [ ! "$__os" = "$_target_os" -a ! "$__os" = "any" ]; then
                        continue
                fi

                if [ ! "$__arch" = "$_target_arch" -a ! "$__arch" = "any" ]; then
                        continue
                fi


                # properly process path
                __path="${__line##* }"
                if [ "${__path%/*}" = "$__path" ]; then
                        FS::make_directory "${_target_directory}"
                else
                        FS::make_directory "${_target_directory}/${__path%/*}"
                fi


                # create command for parallel execution
                if [ ! "${__path%.c*}" = "$__path"  ]; then
                        OS::print_status info "registering .c file...\n"
                        printf -- "%b -o %b -c %b %b\n" \
                                "$_target_compiler" \
                                "${_target_directory}/${__path%.c*}.o" \
                                "${PROJECT_PATH_ROOT}/${_target_source}/${__path}" \
                                "$_target_args" \
                                >> "$_parallel_control"
                        if [ $? -ne 0 ]; then
                                OS::print_status error "register failed.\n\n"
                                return 1
                        fi

                        FS::append_file "$_linker_control" "\
${_target_directory}/${__path%.c*}.o
"
                        if [ $? -ne 0 ]; then
                                OS::print_status error "register failed.\n\n"
                                return 1
                        fi
                elif [ ! "${__path%.nim*}" = "$__path"  ]; then
                        OS::print_status info "registering .nim file...\n"
                        printf -- "%b %b --out:%b %b\n" \
                                "$_target_compiler" \
                                "$_target_args" \
                                "${_target_directory}/${__path%.nim*}" \
                                "${PROJECT_PATH_ROOT}/${_target_source}/${__path}" \
                                >> "$_parallel_control"
                        if [ $? -ne 0 ]; then
                                OS::print_status error "register failed.\n\n"
                                return 1
                        fi

                        FS::append_file "$_linker_control" "\
${_target_directory}/${__path%.nim*}
"
                        if [ $? -ne 0 ]; then
                                OS::print_status error "register failed.\n\n"
                                return 1
                        fi
                elif [ ! "${__path%.o*}" = "$__path"  ]; then
                        OS::print_status info "registering .o file...\n"
                        __target_path="${_target_directory}/${__path}"
                        FS::make_housing_directory "$__target_path"
                        FS::copy_file \
                                "${PROJECT_PATH_ROOT}/${_target_source}/${__path}" \
                                "${__target_path%/*}"
                        if [ $? -ne 0 ]; then
                                OS::print_status error "register failed.\n\n"
                                return 1
                        fi

                        FS::append_file "$_linker_control" "\
${_target_directory}/${__path}
"
                        if [ $? -ne 0 ]; then
                                OS::print_status error "register failed.\n\n"
                                return 1
                        fi
                else
                        OS::print_status error "unsupported file: ${__path}\n\n"
                        return 1
                fi

                _parallel_total=$(($_parallel_total + 1))
        done < "$_target_config"
        IFS="$__old_IFS" && unset __old_IFS


        if [ $_parallel_total -gt 0 ]; then
                printf -- "%b" "$_parallel_total"
        else
                printf -- ""
        fi


        # report status
        return 0
}




BUILD::_exec_compile() {
        #_parallel_control="$1"
        #_target_directory="$2"


        # execute
        _parallel_available=$(getconf _NPROCESSORS_ONLN)
        if [ $_parallel_available -le 0 ]; then
                _parallel_available=1
        fi

        OS::print_status info "begin parallel building with ${_parallel_available} threads...\n"
        SYNC::parallel_exec \
                "BUILD::__exec_compile_source_code" \
                "$1" \
                "$2" \
                "$_parallel_available"
        if [ $? -ne 0 ]; then
                OS::print_status error "Build failed.\n\n"
                return 1
        fi


        # report status
        return 0
}




BUILD::_exec_build() {
        _target_type="$1"
        _target_os="$2"
        _target_arch="$3"
        _target_config="$4"
        _target_args="$5"
        _target_compiler="$6"


        OS::print_status info "validating ${_target_os}-${_target_arch} ${_target_type}...\n"
        _target="${PROJECT_SKU}_${_target_os}-${_target_arch}"
        _target_arch="$(STRINGS::to_lowercase "$_target_arch")"
        _target_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}"
        case "$(STRINGS::to_lowercase "$_target_type")" in
        nim-binary)
                _target_source="$PROJECT_NIM"
                _target_type="none"
                _target_directory="${_target_directory}/nim-bin_${_target}"
                _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${_target}"
                _target_compiler="nim"
                ;;
        nim-test)
                _target_source="$PROJECT_NIM"
                _target_type="none"
                _target_directory="${_target_directory}/nim-test_${_target}"
                _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${_target}"
                _target_compiler="nim"
                ;;
        c-binary)
                _target_source="$PROJECT_C"
                _target_type="bin"
                _target_directory="${_target_directory}/c-bin_${_target}"
                case "$_target_arch" in
                wasm)
                        _target="${_target}.wasm"
                        ;;
                *)
                        _target="${_target}.elf"
                        ;;
                esac
                _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${_target}"
                _target_compiler="$(C::get_compiler \
                        "$_target_os" \
                        "$_target_arch" \
                        "$PROJECT_OS" \
                        "$PROJECT_ARCH" \
                        "$_target_compiler" \
                )"
                if [ $? -ne 0 ]; then
                        OS::print_status warning "No available compiler. Skipping...\n\n"
                        return 10
                else
                        OS::print_status info "selected ${_target_compiler} compiler...\n"
                fi
                ;;
        c-library)
                _target_source="$PROJECT_C"
                _target_type="lib"
                _target="${PROJECT_SKU}-lib_${_target_os}-${_target_arch}"
                _target_directory="${_target_directory}/c-lib_${_target}"
                _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${_target}.a"
                _target_compiler="$(C::get_compiler \
                        "$_target_os" \
                        "$_target_arch" \
                        "$PROJECT_OS" \
                        "$PROJECT_ARCH" \
                        "$_target_compiler" \
                )"
                if [ $? -ne 0 ]; then
                        OS::print_status warning "No available compiler. Skipping...\n\n"
                        return 10
                else
                        OS::print_status info "selected ${_target_compiler} compiler...\n"
                fi
                ;;
        c-test)
                _target_source="$PROJECT_C"
                _target_type="test-bin"
                _target_directory="${_target_directory}/c-test_${_target}"
                _target="${_target_directory}"
                _target_compiler="$(C::get_compiler \
                        "$_target_os" \
                        "$_target_arch" \
                        "$PROJECT_OS" \
                        "$PROJECT_ARCH" \
                        "$_target_compiler" \
                )"
                if [ $? -ne 0 ]; then
                        OS::print_status warning "No available compiler. Skipping...\n\n"
                        return 10
                else
                        OS::print_status info "selected ${_target_compiler} compiler...\n"
                fi
                ;;
        *)
                OS::print_status error "validation failed.\n\n"
                return 1
                ;;
        esac
        _parallel_control="${_target_directory}/sync.txt"
        _linker_control="${_target_directory}/o-list.txt"
        _parallel_total=0


        OS::print_status info "validating config file (${_target_config##*/}) existence...\n"
        _target_config="$(BUILD::__validate_config_file "$_target_config" "$_target_source")"
        if [ "$_target_config" = "" ]; then
                OS::print_status error "validation failed.\n\n"
                return 1
        fi


        OS::print_status info "preparing ${_target} parallel build workspace...\n"
        FS::remove_silently "${_parallel_control}"
        FS::remove_silently "${_linker_control}"


        # validating each source files
        _parallel_total="$(BUILD::__validate_source_files \
                "$_target_config" \
                "$_target_source" \
                "$_target_compiler" \
                "$_target_args" \
                "$_target_directory" \
                "$_linker_control" \
                "$_target_os" \
                "$_target_arch" \
        )"
        if [ "$_parallel_total" = "" ]; then
                return 1
        elif [ $_parallel_total -eq 0 ]; then
                return 1
        fi


        # compile all object files
        BUILD::_exec_compile "$_parallel_control" "$_target_directory"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # link all objects
        BUILD::_exec_link \
                "$_target_type" \
                "$_target" \
                "$_target_directory" \
                "$_linker_control" \
                "$_target_compiler"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




BUILD::_exec_link() {
        _target_type="$1"
        _target="$2"
        _target_directory="$3"
        _linker_control="$4"
        _target_compiler="$5"


        # validate input
        OS::print_status info "checking linking control file (${_linker_control})...\n"
        FS::is_file "$_linker_control"
        if [ $? -ne 0 ]; then
                OS::print_status error "check failed.\n\n"
                return 1
        fi


        # link all objects
        case "$_target_type" in
        none)
                OS::print_status info "linking object file into executable...\n"
                ;;
        test-bin)
                OS::print_status info "linking object file into executable...\n"
                old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        _target="${__line%.*}"
                        FS::remove_silently "$_target"
                        if [ $? -ne 0 ]; then
                                OS::print_status error "link failed.\n\n"
                                return 1
                        fi

                        "$_target_compiler" -o "${_target}" "$__line"
                        if [ $? -ne 0 ]; then
                                OS::print_status error "link failed.\n\n"
                                return 1
                        fi

                        FS::remove_silently "$__line"
                        if [ $? -ne 0 ]; then
                                OS::print_status error "link failed.\n\n"
                                return 1
                        fi
                done < "$_linker_control"
                IFS="$old_IFS" && unset old_IFS
                ;;
        bin)
                OS::print_status info "linking all object files into executable...\n"
                FS::remove_silently "$_target"
                if [ $? -ne 0 ]; then
                        OS::print_status error "link failed.\n\n"
                        return 1
                fi

                "$_target_compiler" -o "$_target" @"$_linker_control"
                if [ $? -ne 0 ]; then
                        OS::print_status error "link failed.\n\n"
                        return 1
                fi
                ;;
        lib)
                FS::remove_silently "$_target"
                if [ $? -ne 0 ]; then
                        OS::print_status error "link failed.\n\n"
                        return 1
                fi

                old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        OS::print_status info "linking into library ${__line}\n"
                        ar -cr "$_target" "$__line"
                        if [ $? -ne 0 ]; then
                                OS::print_status error "link failed.\n\n"
                                return 1
                        fi
                done < "$_linker_control"
                IFS="$old_IFS" && unset old_IFS
                ;;
        *)
                return 1
                ;;
        esac


        # report status
        return 0
}




BUILD::compile() {
        #_target_type="$1"
        #_target_os="$2"
        #_target_arch="$3"
        #_target_config="$4"
        #_target_args="$5"
        #_target_compiler="$6"


        # execute
        FS::make_directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
        BUILD::_exec_build "$1" "$2" "$3" "$4" "$5" "$6"
        case $? in
        0)
                ;;
        10)
                return 10
                ;;
        *)
                return 1
                ;;
        esac


        # report status
        OS::print_status success "\n\n"
        return 0
}




BUILD::test() {
        #_target_type="$1"
        _target_os="$2"
        _target_arch="$3"
        #_target_args="$4"
        #_target_compiler="$5"


        # prepare test environment
        _target="${PROJECT_SKU}_${_target_os}-${_target_arch}"
        _target_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}"


        # scan for all test source codes
        OS::print_status info "setup test workspace...\n"
        case "$1" in
        "$PROJECT_NIM")
                OS::print_status info "scanning all nim test codes...\n"
                _target_code="nim-test"
                _target_directory="${_target_directory}/${_target_code}_${_target}"
                _target_build_list="${_target_directory}/build-list.txt"

                FS::remake_directory "$_target_directory"

                __old_IFS="$IFS"
                find "${PROJECT_PATH_ROOT}/${PROJECT_NIM}" -name '*_test.nim' -print0 \
                | while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line#*${PROJECT_PATH_ROOT}/${PROJECT_NIM}/}"

                        OS::print_status info "registering ${__line}\n"
                        FS::append_file \
                                "$_target_build_list" \
                                "${_target_os}-${_target_arch} ${__line}\n"
                done
                IFS="$__old_IFS" && unset __old_IFS
                ;;
        "$PROJECT_C")
                OS::print_status info "scanning all C test codes...\n"
                _target_code="c-test"
                _target_directory="${_target_directory}/${_target_code}_${_target}"
                _target_build_list="${_target_directory}/build-list.txt"

                FS::remake_directory "$_target_directory"

                __old_IFS="$IFS"
                find "${PROJECT_PATH_ROOT}/${PROJECT_C}" -name '*_test.c' -print0 \
                | while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line#*${PROJECT_PATH_ROOT}/${PROJECT_C}/}"

                        OS::print_status info "registering ${__line}\n"
                        FS::append_file \
                                "$_target_build_list" \
                                "${_target_os}-${_target_arch} ${__line}\n"
                done
                IFS="$__old_IFS" && unset __old_IFS
                ;;
        *)
                OS::print_status error "unsupported tech.\n"
                return 1
                ;;
        esac


        # check if no test is available, get out early.
        if [ ! -f "$_target_build_list" ]; then
                OS::print_status success "\n\n"
                return 0
        fi


        # build all test artifacts
        BUILD::_exec_build "$_target_code" "$2" "$3" "$_target_build_list" "$4" "$5"
        case $? in
        0)
                ;;
        10)
                return 10
                ;;
        *)
                return 1
                ;;
        esac


        # execute all test artifacts
        _target_config="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
        _target_config="${_target_code}_${_target_config}"
        _target_config="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${_target_config}"
        _target_config="${_target_config}/o-list.txt"

        OS::print_status info "checking test execution workspace...\n"
        FS::is_file "$_target_config"
        if [ $? -ne 0 ]; then
                OS::print_status error "check failed - missing compatible workspace.\n"
        fi

        EXIT_CODE=0
        __old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                __line="${__line%.*}"
                OS::print_status info "testing ${__line}\n"

                $__line
                if [ $? -ne 0 ]; then
                        EXIT_CODE=1
                fi
        done < "$_target_config"
        IFS="$__old_IFS" && unset __old_IFS


        # report status
        if [ $EXIT_CODE -ne 0 ]; then
                OS::print_status error "test failed.\n\n"
                return 1
        fi

        OS::print_status success "\n\n"
        return 0
}




# report status
return 0

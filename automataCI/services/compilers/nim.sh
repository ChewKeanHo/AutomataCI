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
. "${LIBS_AUTOMATACI}/services/io/sync.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




NIM_Activate_Local_Environment() {
        # validate input
        NIM_Is_Available
        if [ $? -ne 0 ] ; then
                return 1
        fi

        NIM_Is_Localized
        if [ $? -eq 0 ] ; then
                return 0
        fi


        # execute
        ___location="$(NIM_Get_Activator_Path)"
        FS_Is_File "$___location"
        if [ $? -ne 0 ]; then
                return 1
        fi

        . "$___location"

        NIM_Is_Localized
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NIM_Check_Package() {
        #___directory="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi


        # execute
        ___current_path="$PWD" && cd "$1"
        nimble check
        ___process=$?
        cd "$___current_path" && unset ___current_path
        if [ $___process -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NIM_Get_Activator_Path() {
        printf -- "%b" "${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_NIM_ENGINE}/activate.sh"
}




NIM_Is_Available() {
        # execute
        OS_Sync

        OS_Is_Command_Available "nim"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "nimble"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NIM_Is_Localized() {
        # execute
        if [ $(STRINGS_Is_Empty "$PROJECT_NIM_LOCALIZED") -ne 0 ]; then
                return 0
        fi


        # report status
        return 1
}




NIM_Run_Parallel() {
        #___line="$1"


        # parse input
        ___mode="${1%%|*}"
        ___arguments="${1#*|}"

        ___directory_source="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___directory_workspace="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___directory_log="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___target="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___target_os="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___target_arch="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"


        # validate input
        if [ $(STRINGS_Is_Empty "$___mode") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___directory_source") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___directory_workspace") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___directory_log") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target_os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target_arch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arguments") -eq 0 ]; then
                return 1
        fi

        ___mode="$(STRINGS_To_Lowercase "$___mode")"
        case "$___mode" in
        build|test)
                # accepted
                ;;
        *)
                return 1
                ;;
        esac

        ___target="$(FS_Get_Path_Relative "$___target" "$___directory_source")"
        ___directory_target="$(FS_Get_Directory "$___target")"
        ___file_target="$(FS_Get_File "$___target")"

        ___file_log="$___directory_log"
        ___file_output="$___directory_workspace"
        if [ ! "$___directory_target" = "$___file_target" ]; then
                # there are sub-directories
                ___file_log="${___file_log}/${___directory_target}"
                ___file_output="${___file_output}/${___directory_target}"
        fi

        ___file_target="$(FS_Extension_Remove "$___file_target" "*")"
        if [ "$___mode" = "test" ]; then
                ___file_log="${___file_log}/${___file_target}_test.log"
        else
                ___file_log="${___file_log}/${___file_target}_build.log"
        fi
        FS_Make_Housing_Directory "$___file_log"

        ___file_output="${___file_output}/${___file_target}"
        case "$___target_os" in
        windows)
                ___file_output="${___file_output}.exe"
                ;;
        *)
                ___file_output="${___file_output}.elf"
                ;;
        esac
        FS_Make_Housing_Directory "$___file_output"

        if [ "$___mode" = "test" ]; then
                I18N_Test "$___file_output" >> "$___file_log" 2>&1
                if [ ! "$___target_os" = "$PROJECT_OS" ]; then
                        I18N_Test_Skipped >> "$___file_log" 2>&1
                        return 10 # skipped - cannot operate in host environment
                fi

                FS_Is_File "$___file_output"
                if [ $? -ne 0 ]; then
                        I18N_Test_Failed >> "$___file_log" 2>&1
                        return 1 # failed - build stage
                fi

                $___file_output >> "$___file_log" 2>&1
                if [ $? -ne 0 ]; then
                        I18N_Test_Failed >> "$___file_log" 2>&1
                        return 1 # failed - test stage
                fi


                # report status (test mode)
                return 0
        fi


        # operate in build mode
        ___command="\
nim ${___arguments} --out:${___file_output} ${___directory_source}/${___target}
"


        # execute
        I18N_Build "$___command" >> "$___file_log" 2>&1
        $___command >> "$___file_log" 2>&1
        if [ $? -ne 0 ]; then
                I18N_Build_Failed >> "$___file_log" 2>&1
                return 1
        fi


        # report status (build mode)
        return 0
}




NIM_Run_Test() {
        ___directory="$1"
        ___os="$2"
        ___arch="$3"
        ___arguments="$4"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arguments") -eq 0 ]; then
                return 1
        fi

        NIM_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/test-${PROJECT_NIM}"
        ___log="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/test-${PROJECT_NIM}"
        ___build_list="${___workspace}/build-list.txt"
        ___test_list="${___workspace}/test-list.txt"
        FS_Remake_Directory "$___workspace"
        FS_Remake_Directory "$___log"

        ## (1) Scan for all test files
        __old_IFS="$IFS"
        find "$___directory" -name '*_test.nim'  -printf "%p\n" \
                | while IFS= read -r __line || [ -n "$__line" ]; do
                FS_Append_File "$___build_list" "\
build|${___directory}|${___workspace}|${___log}|${__line}|${___os}|${___arch}|${___arguments}
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                FS_Append_File "$___test_list" "\
test|${___directory}|${___workspace}|${___log}|${__line}|${___os}|${___arch}|${___arguments}
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done
        IFS="$__old_IFS" && unset __old_IFS

        ## (2) Bail early if test is unavailable
        FS_Is_File "$___build_list"
        if [ $? -ne 0 ]; then
                return 0
        fi

        FS_Is_File "$___test_list"
        if [ $? -ne 0 ]; then
                return 0
        fi

        ## (3) Build all test artifacts
        SYNC_Exec_Parallel "NIM_Run_Parallel" "$___build_list" "$___workspace"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ## (4) Execute all test artifacts
        SYNC_Exec_Parallel "NIM_Run_Parallel" "$___test_list" "$___workspace"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # Report status
        return 0
}




NIM_Setup() {
        # validate input
        NIM_Is_Available
        if [ $? -eq 0 ]; then
                return 0
        fi

        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        brew install nim
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NIM_Setup_Local_Environment() {
        # validate input
        NIM_Is_Localized
        if [ $? -eq 0 ] ; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_ROOT") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_TOOLS") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_NIM_ENGINE") -eq 0 ]; then
                return 1
        fi

        NIM_Is_Available
        if [ $? -ne 0 ] ; then
                return 1
        fi


        # execute
        ___label="($PROJECT_PATH_NIM_ENGINE)"
        ___location="$(NIM_Get_Activator_Path)"

        if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
                ___brew="eval \$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [ -f "/usr/local/bin/brew" ]; then
                ___brew="eval \$(/usr/local/bin/brew shellenv)"
        else
                ___brew=""
        fi

        FS_Make_Housing_Directory "$___location"
        FS_Write_File "$___location" "\
#!/bin/sh
if [ -z \"\$(type -t 'nim')\" ]; then
        1>&2 printf -- '[ ERROR ] missing nim compiler.\\\\n'
        return 1
fi

if [ -z \"\$(type -t 'nimble')\" ]; then
        1>&2 printf -- '[ ERROR ] missing nimble package manager.\\\\n'
        return 1
fi

deactivate() {
        if [ -z \"\$old_NIMBLE_DIR\" ]; then
                unset old_NIMBLE_DIR NIMBLE_DIR
        else
                NIMBLE_DIR=\"\$old_NIMBLE_DIR\"
                unset old_NIMBLE_DIR
        fi
        export PS1=\"\${PS1##*${___label} }\"
        unset PROJECT_NIM_LOCALIZED
        return 0
}

# check
if [ ! -z \"\$PROJECT_NIM_LOCALIZED\" ]; then
        return 0
fi

# activate
${___brew}
export old_NIMBLE_DIR=\"\$NIMBLE_DIR\"
export NIMBLE_DIR=\"$(FS_Get_Directory "${___location}")\"
export PROJECT_NIM_LOCALIZED='${___location}'
export PS1=\"${___label} \${PS1}\"
return 0
"
        FS_Is_File "${___location}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # testing the activation
        NIM_Activate_Local_Environment
        if [ $? -ne 0 ] ; then
                return 1
        fi


        # report status
        return 0
}

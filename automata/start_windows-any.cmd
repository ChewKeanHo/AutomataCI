REM Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
REM
REM Licensed under the Apache License, Version 2.0 (the "License"); you may not
REM use this file except in compliance with the License. You may obtain a copy
REM of the License at:
REM               http://www.apache.org/licenses/LICENSE-2.0
REM Unless required by applicable law or agreed to in writing, software
REM distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
REM WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
REM License for the specific language governing permissions and limitations
REM under the License.
@echo off




REM (0) initialize
set code=0
IF NOT EXIST %PROJECT_PATH_ROOT% (
        echo "[ ERROR ] - Please source from ci.cmd instead!\n"
        set code=1
        goto end
)




REM (1) your unix commands for the job recipe here. You can source the pre-built
REM     templates inside the ./scripts/templates directory to jump-start a
REM     supported project. Example, for Go you can add the following:
REM          . ${PROJECT_PATH_SCRIPTS}/templates/go/start_${PROJECT_OS}-${PROJECT_ARCH}.sh
REM          if [ $? -ne 0 ]; then
REM                # handle error here
REM                return 1
REM          fi
echo "Hello from native CI - start recipe!\n"




:end
EXIT /B %code%

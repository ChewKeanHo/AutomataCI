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
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/__printer.sh"




I18N_Help() {
        ___mode="$1"
        ___executable="$2"


        # validate input
        if [ "$(STRINGS_Is_Empty "$___mode")" -eq 0 ]; then
                ___mode="info"
        fi

        if [ "$(STRINGS_Is_Empty "$___executable")" -eq 0 ]; then
                ___executable="./automataCI/ci.sh.ps1"
        fi


        # execute
        case "$AUTOMATACI_LANG" in
        *)
                # fallback to default english
                I18N_Status_Print "$___mode" "\

Please try any of the following:
        To seek commands' help 🠚               $ ${___executable} help
        To initialize environment 🠚            $ ${___executable} env
        To setup the repo for work 🠚           $ ${___executable} setup
        To prepare the repo 🠚                  $ ${___executable} prepare
        To start a development 🠚               $ ${___executable} start
        To test the repo 🠚                     $ ${___executable} test
        To build but for host system only 🠚    $ ${___executable} materialize
        To build the repo 🠚                    $ ${___executable} build
        To notarize the builds 🠚               $ ${___executable} notarize
        To package the repo product 🠚          $ ${___executable} package
        To release the repo product 🠚          $ ${___executable} release
        To stop a development 🠚                $ ${___executable} stop
        To archive the workspace 🠚             $ ${___executable} archive
        To deploy the new release 🠚            $ ${___executable} deploy
        To clean the workspace 🠚               $ ${___executable} clean
        To purge everything 🠚                  $ ${___executable} purge

"
                ;;
        esac
        unset ___mode  ___executable


        # report status
        return 0
}

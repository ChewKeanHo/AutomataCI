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
. "${LIBS_AUTOMATACI}/services/i18n/__param.sh"
. "${LIBS_AUTOMATACI}/services/i18n/__printer.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_activate-environment.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_activate-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_archive.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_archive-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_assemble.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_assemble-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_assemble-package.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_assemble-skipped.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_check.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_check-availability.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_check-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_check-failed-skipped.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_check-function.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_check-incompatible-skipped.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_check-login.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_checksum.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_checksum-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_clean.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_clean-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_commit.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_commit-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_copy.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_copy-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_create.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_create-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_create-package.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_detected.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_export.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_export-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_export-missing.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_file-bad-stat-skipped.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_guide-start-activate.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_guide-stop-deactivate.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_help.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_injection-manual-detected.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_install.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_install-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_is-directory-skipped.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_is-incompatible-skipped.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_logout.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_logout-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_missing.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_newline.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_notarize-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_notarize-not-applicable.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_notarize-unavailable.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_package.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_package-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_parse.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_parse-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_prepare.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_prepare-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_processing.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_processing-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_processing-test-coverage.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_publish.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_publish-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_purge.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_remake.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_remake-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_run.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_run-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_run-successful.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_run-test-coverage.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_setup.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_setup-environment.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_setup-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_shasum.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_shasum-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_sign.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_sign-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_simulate-available.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_simulate-conclusion.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_simulate-notarize.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_simulate-publish.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_source.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_source-skipped.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_sync-register.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_sync-report-log.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_sync-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_sync-run.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_sync-run-series.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_sync-run-skipped.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_test.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_test-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_test-skipped.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_unknown-action.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_unsupported-arch.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_unsupported-os.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_update.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_update-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_validate.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_validate-failed.sh"
. "${LIBS_AUTOMATACI}/services/i18n/_validate-job.sh"

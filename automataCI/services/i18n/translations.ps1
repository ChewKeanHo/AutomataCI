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
. "${env:LIBS_AUTOMATACI}\services\i18n\__param.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\__printer.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_activate-environment.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_activate-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_archive.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_archive-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_assemble.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_assemble-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_assemble-package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_assemble-skipped.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_check.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_check-availability.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_check-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_check-failed-skipped.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_check-function.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_check-incompatible-skipped.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_check-login.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_checksum.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_checksum-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_clean.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_clean-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_commit.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_commit-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_copy.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_copy-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_create.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_create-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_create-package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_detected.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_export.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_export-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_export-missing.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_file-bad-stat-skipped.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_guide-start-activate.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_guide-stop-deactivate.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_help.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_import-dependencies.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_import-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_injection-manual-detected.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_install.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_install-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_is-directory-skipped.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_is-incompatible-skipped.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_logout.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_logout-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_missing.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_newline.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_notarize-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_notarize-not-applicable.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_notarize-unavailable.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_package-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_parse.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_parse-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_prepare.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_prepare-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_processing.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_processing-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_processing-test-coverage.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_publish.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_publish-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_purge.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_remake.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_remake-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_run.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_run-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_run-successful.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_run-test-coverage.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_setup.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_setup-environment.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_setup-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_shasum.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_shasum-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_sign.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_sign-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_simulate-available.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_simulate-conclusion.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_simulate-notarize.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_simulate-publish.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_source.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_source-skipped.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_sync-register.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_sync-report-log.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_sync-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_sync-run.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_sync-run-series.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_sync-run-skipped.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_test.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_test-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_test-skipped.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_unknown-action.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_unsupported-arch.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_unsupported-os.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_update.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_update-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_validate.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_validate-failed.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_validate-job.ps1"

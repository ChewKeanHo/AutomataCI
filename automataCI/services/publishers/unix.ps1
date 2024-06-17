# Copyright 2024 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function UNIX-Get-Arch {
	param(
		[string]$___arch
	)


	# execute
	switch ($___arch) {
	"any" {
		return "all"
	} { $_ -in "386", "i386", "486", "i486", "586", "i586", "686", "i686" } {
		return "i386"
	} "armle" {
		return "armel"
	} "mipsle" {
		return "mipsel"
	} "mipsr6le" {
		return "mips64r6el"
	} "mipsn32le" {
		return "mipsn32el"
	} "mipsn32r6le" {
		return "mipsn32r6el"
	} "mips64le" {
		return "mips64el"
	} "mipsn64r6le" {
		return "mipsn64r6el"
	} "powerpcle" {
		return "powerpcel"
	} "ppc64le" {
		return "ppc64el"
	} default {
		return $___arch
	}}
}

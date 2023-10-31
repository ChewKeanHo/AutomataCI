# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




# define configurations
$url = "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-gnu/rustup-init.exe"
$dir = ".\.tmp"
$dest = "${dir}\rustup-init.exe"




# download and setup rust
Write-Host "info: downloading rustup-init.exe..."
if (-not (Test-Path "${dir}")) {
	New-Item -ItemType directory -Path "${dir}"
}


$null = Start-BitsTransfer -Source $url -Destination $dest
if (-not (Test-Path "$dest")) {
	Write-Error "info: download failed."
	$null = Remove-Item -Path "${dir}" -Recurse -Force -ErrorAction SilentlyContinue
	return 1
}




# execute installation
Write-Host "info: executing rustup-init.exe..."
$null = Invoke-Expression "$dest -y"
$null = Remove-Item -Path "${dir}" -Recurse -Force -ErrorAction SilentlyContinue




# report status
return 0

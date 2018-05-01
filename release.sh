#!/bin/bash

# Prerequisites
## git
## aria2c or wget
## curl
## 7z
## internet access

downloader="null"
init_downloader() {
    if which aria2c; then
        downloader=(aria2c -s16 -x16 -k1M -c --file-allocation=falloc)
    elif which wget; then
        downloader=(wget -t3 -c)
    else
        echo 'fatal: cannot find a downloader'
    fi
}
fetch() {
    if [[ "${downloader}" = "null" ]]; then
        init_downloader
    fi
    "${downloader[@]}" -o "$2" "$1"
}

update_ffmpeg() {
    local b='64'
    if [[ "$1" = "32" ]]; then
        b='32'
    fi
    local filename=$(eval echo "\${ffmpeg_version_remote_${b}}")
    local url="$(eval echo "\${ffmpeg_url_${b}}")${filename}"
    local path="$(echo "${filename}" | sed 's/\.zip$//')"
    echo Downloading "${filename}" ...
    fetch "${url}" "${filename}"
    echo Unpacking "${filename}" ...
    unzip -qo "${filename}"
    echo Updating ffmpeg "${b}-bit" ...
    mv -f "${path}/bin/ffmpeg.exe" "bin${b}/"
    echo Cleaning up ffmpeg "${b}-bit" files...
    rm -rf "./${path}/presets" "./${path}/doc"
    rm -f "./${path}/bin/ffplay.exe" "./${path}/bin/ffprobe.exe" "./${path}/LICENSE.txt" "./${path}/README.txt" "${filename}"
    rm -d "${path}/bin" "${path}"
}

echo Fetching remote ffmpeg info...
ffmpeg_regex='ffmpeg-\d+-[\da-f]+-win\d\d-.+?\.zip'
ffmpeg_url_64='https://ffmpeg.zeranoe.com/builds/win64/static/'
ffmpeg_url_32='https://ffmpeg.zeranoe.com/builds/win32/static/'
ffmpeg_version_remote_64="$(curl -L -s "${ffmpeg_url_64}" | grep -ioP "${ffmpeg_regex}" | uniq | sort -r | head -1)"
ffmpeg_version_remote_32="$(curl -L -s "${ffmpeg_url_32}" | grep -ioP "${ffmpeg_regex}" | uniq | sort -r | head -1)"
ffmpeg_date_remote_64="$(echo "${ffmpeg_version_remote_64}" |  grep -ioP '\d{8}')"
ffmpeg_date_remote_32="$(echo "${ffmpeg_version_remote_32}" |  grep -ioP '\d{8}')"
ffmpeg_date_64="$(stat -c %Y bin64/ffmpeg | xargs -I '*' date -d@'*' '+%0000Y%00m%00d')"
ffmpeg_date_32="$(stat -c %Y bin32/ffmpeg | xargs -I '*' date -d@'*' '+%0000Y%00m%00d')"

echo Remote 64-bit ffmpeg date: $ffmpeg_date_remote_64
echo Local 64-bit ffmpeg date: $ffmpeg_date_64
echo Remote 32-bit ffmpeg date: $ffmpeg_date_remote_32
echo Local 32-bit ffmpeg date: $ffmpeg_date_32

if [[ $ffmpeg_date_remote_64 > $ffmpeg_date_64 ]]; then
    update_ffmpeg 64
fi

if [[ $ffmpeg_date_remote_32 > $ffmpeg_date_32 ]]; then
    update_ffmpeg 32
fi

echo Fetching busybox info...
busybox_info_url='https://frippery.org/busybox/'
busybox_bin_url='https://frippery.org/files/busybox/'
busybox_version_64="$("./bin64/busybox64.exe" | head -1 | grep -ioP '\d+-g[\da-z]+' | grep -ioP '\d+' | head -1)"
busybox_version_32="$("./bin32/busybox.exe" | head -1 | grep -ioP '\d+-g[\da-z]+' | grep -ioP '\d+' | head -1)"
busybox_version_remote="$(curl -k -s -L --retry 5 --retry-connrefused "${busybox_info_url}" | grep -ioP '\d+-g[\da-z]+' | uniq | grep -ioP '\d+' | head -1)"
echo Remote busybox version: $busybox_version_remote
echo Local 64-bit busybox version: $busybox_version_64
echo Local 32-bit busybox version: $busybox_version_32

if [[ $busybox_version_64 < $busybox_version_remote ]]; then
    echo Updating busybox 64-bit...
    fetch "${busybox_bin_url}busybox64.exe" "busybox64_${busybox_version_remote}.exe"
    "./busybox64_${busybox_version_remote}" && mv -f "busybox64_${busybox_version_remote}.exe" "./bin64/busybox64.exe"
fi

if [[ $busybox_version_32 < $busybox_version_remote ]]; then
    echo Updating busybox 32-bit...
    fetch "${busybox_bin_url}busybox.exe" "busybox_${busybox_version_remote}.exe"
    "./busybox_${busybox_version_remote}" && mv -f "busybox_${busybox_version_remote}.exe" "./bin32/busybox.exe"
fi

echo Downloading mujs if not exist...
mujs_url='https://ci.appveyor.com/api/projects/myfreeer/mujs/artifacts/'
[[ ! -e bin64/mujs.exe ]] && fetch "${mujs_url}mujs_x64.7z" mujs_x64.7z && 7z x mujs_x64.7z && mv -f mujs.exe bin64/ && rm -f mujs_x64.7z
[[ ! -e bin32/mujs.exe ]] && fetch "${mujs_url}mujs_x86.7z" mujs_x86.7z && 7z x mujs_x86.7z && mv -f mujs.exe bin32/ && rm -f mujs_x86.7z

echo Packaging nogui...
nogui_date="$(git log -n1 --date=short --pretty=format:'%ad' | sed  's/-//g')"
nogui_ver="$(git describe --tags)"
package_name="nogui-${nogui_date}-${nogui_ver}.7z"
[[ ! -e  "${package_name}" ]] && 7z a -mx9 -myx9 "${package_name}" "*" -xr!"*.7z" -xr!".git" -xr!".gitignore" -xr!"tmp"

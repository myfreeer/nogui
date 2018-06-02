# nogui
a multimedia encoding tool without gui

## Usage (Release)
1. Download latest [release package](https://github.com/myfreeer/nogui/releases/latest) and extract it to a folder containing no space or non-ascii chars.
2. (Optional) Check and modify `config.ini`
    * Check [config.md](config.md) for references.
3. Drag file(s) to `nogui.bat` and wait until completed. The encoded file should be in the same folder of input file.
    * Multimedia encoding usually takes a long time, so be patient.
    
## Usage (Manally)
1. Download [this project](https://github.com/myfreeer/nogui/archive/master.zip) as archive and extract it to a folder containing no space or non-ascii chars.
2. Download or compile [busybox-w32](https://frippery.org/busybox/) and put `busybox.exe` in `bin` folder.
    * The 32-bit `busybox.exe` should be put in `bin32` folder.
        * You may get latest 32-bit binary from [frippery's website](https://frippery.org/files/busybox/busybox.exe)
    * The 64-bit `busybox.exe` or `busybox64.exe` should be put in `bin64` folder.
        * You may get latest 64-bit binary from [frippery's website](https://frippery.org/files/busybox/busybox64.exe)
3. Download or compile [ffmpeg](https://ffmpeg.org/).
    * The 32-bit `ffmpeg.exe` should be put in `bin32` folder.
        * You may get latest 32-bit binary from [Zeranoe's website](https://ffmpeg.zeranoe.com/builds/win32/static/ffmpeg-latest-win32-static.zip)
    * The 64-bit `ffmpeg.exe` should be put in `bin64` folder.
        * You may get latest 64-bit binary from [Zeranoe's website](https://ffmpeg.zeranoe.com/builds/win64/static/ffmpeg-latest-win64-static.zip)
4. (Optional) Compile [fdkaac](https://github.com/nu774/fdkaac) if needed
    * `fdkaac` enables high-quality aac audio encoding for better compibility with legacy devices.
    * Fraunhofer's [license](https://android.googlesource.com/platform/external/aac/+/master/NOTICE) prevented a binary being released.
    * [fdkaac_autobuild](https://github.com/nu774/fdkaac_autobuild) can compile `fdkaac` easily on windows.
    * The 32-bit `fdkaac.exe` should be put in `bin32` folder.
    * The 64-bit `fdkaac.exe` should be put in `bin64` folder.
5. (Optional) Download or compile **CLI** version of [MediaInfo](https://mediaarea.net/en/MediaInfo/Download/Windows) if needed
    * Both `MediaInfo` and `mujs` are required for HDR metadata parsing.
    * The 32-bit `MediaInfo.exe` should be put in `bin32` folder.
    * The 64-bit `MediaInfo.exe` should be put in `bin64` folder.
6. (Optional) Compile [mujs](https://artifex.com/mujs/) if needed
    * Both `MediaInfo` and `mujs` are required for HDR metadata parsing.
    * The 32-bit `mujs.exe` should be put in `bin32` folder.
        * Alternatively, you may get a 32-bit binary from [here](https://ci.appveyor.com/api/projects/myfreeer/mujs/artifacts/mujs_x86.7z)
    * The 64-bit `mujs.exe` should be put in `bin64` folder.
        * Alternatively, you may get a 64-bit binary from [here](https://ci.appveyor.com/api/projects/myfreeer/mujs/artifacts/mujs_x64.7z)
7. (Optional) Check and modify `config.ini`
    * Check [config.md](config.md) for references.
8. Drag file(s) to `nogui.bat` and wait until completed. The encoded file should be in the same folder of input file.
    * Multimedia encoding usually takes a long time, so be patient.

## FAQ
* How to stop (give up) a encoding session?
    * Click the `X` button at the top right corner of the console window.
* How to pause/resume a encoding session?
    * Pause: Right click the title bar of the console window, choose `Edit` -> `Mark` to pause.
    * Resume: Right click inside the paused console window to resume.
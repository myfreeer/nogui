# Nogui Config Reference
## Global
### `Encode_Type`
Type of destination file. Wrong `Encode_Type` may lead to wrong result.

* Possible Values
    * `Video` (Default)
    * `Audio`

### `Log_File`
If set, nogui would log the encoding process to specified file.

**Note:** If `Log_File` is set, encoding process **can't be paused** via `Pause/Break` key or `Ctrl+S` hotkey.

### `Locale`
If set, nogui would try to use the locale specified here instead of detecting it from registry.
Nogui would fallback to english (en-US) if the specified locale does not exist in `locale` folder.

* Default: Not set (RECOMMANDED)

### `Output_Path`
If set, nogui would write output file to the path specified here instead of the path of input file.

* Default: Not set (RECOMMANDED)

### `Output_File_Format`
The extension of output file. Recommended to use `mkv` for videos, and `mka` for audios.

* Default: `mkv`

### `Nogui_Preset`
A set of options and values. **Any** other value would override this.

* Default: Not set
* Possible Values
    * `hq`
        * `Video_Encode_Codec`=`x265`
        * `Audio_Encode_Codec`=`opus`
        * `Video_Encode_Preset`=`slower`
        * `Pixel_Format`=`yuv420p10le`
        * `Video_Encode_Custom_Params`=`aq-mode=2:weightb=1:rc-lookahead=120:keyint=720:min-keyint=1`
        * `Video_Encode_Quality`=`18`
        * `Audio_Encode_Quality`=`4`
    * `x265_fast`
        * `Video_Encode_Codec`=`x265`
        * `Audio_Encode_Codec`=`opus`
        * `Video_Encode_Preset`=`fast`
        * `Video_Encode_Custom_Params`=`aq-mode=2:weightb=1:merange=16:keyint=720:min-keyint=1`
        * `Video_Encode_Quality`=`21`
        * `Audio_Encode_Quality`=`3`
    * `sd`
        * `Video_Encode_Codec`=`x264`
        * `Audio_Encode_Codec`=`fdkaac`
        * `Video_Encode_Preset`=`veryslow`
        * `Pixel_Format`=`yuv420p`
        * `Video_Encode_Custom_Params`=`bframes=16:weightb=1:keyint=720:min-keyint=1`
        * `Video_Encode_Quality`=`21`
        * `Audio_Encode_Quality`=`3`
        * `Audio_Encode_Profile`=`29`
        * `Audio_Encode_Channels`=`2`
        * `Resize`=`sd`

### `FFmpeg_Hwaccel`
Use hardware acceleration to decode the matching stream(s), passed to ffmpeg as `hwaccel` directly.
Run `ffmpeg -hwaccels` for available values for your current ffmpeg build.

* Default: Not set.

## Video
### `Video_Encode_Codec`
The codec for video encoding.

* Possible Values
    * `x265` (Default)
    * `x264`

### `Video_Encode_Quality`
Quality for video encoding, the `crf` value passed to ffmpeg.

* Possible Values: `0-51`, smaller for better quality anf larger file size.
* Default Value: `21`

### `Video_Encode_Preset`
Preset for video encoding, passed to ffmpeg as `preset:v` directly.

* Default Value: `slow`
* Possible Values (**Bold** ones are recommended):
    * `ultrafast`
    * `superfast`
    * `veryfast`
    * `faster`
    * **`fast`**
    * **`medium`**
    * **`slow`**
    * **`slower`**
    * **`veryslow`**
    * `placebo`
* Reference for `x265`: http://x265.readthedocs.io/en/default/presets.html
* Reference for `x264`: http://dev.beandog.org/x264_preset_reference.html

### `Video_Encode_Custom_Params`
Custom parameter passed to codec directly.
Values here overrides values set in `Video_Encode_Preset`

* Default Value: `aq-mode=2:weightb=1:rc-lookahead=120:keyint=720:min-keyint=1`
* Reference for `x265`: http://x265.readthedocs.io/en/default/cli.html
* Reference for `x264`: http://www.chaneru.com/Roku/HLS/X264_Settings.htm

### `Auto_Crop`
Use ffmpeg's `cropdetect` filter to detect black edges in time-range `10:00` to `12:00` and apply a `crop` filter to video based on result above.

* Possible Values
    * `0`: Disable (Default)
    * `1`: Enable

### `Crop`
Manally apply a `crop` filter as `crop=value` to video.
This would override value of `Auto_Crop` if set.

Notice: the `crop` filter will be put before the `scale` filter.

### `Resize`
Apply a `scale` filter to video.

* Possible Values
    * `0`: Disable (Default)
    * `half`: Resize to half the size of source
    * `sd`: Resize the width to `854` and keep aspect ratio
    * `hd`: Resize the width to `1280` and keep aspect ratio
    * `fhd`: Resize the width to `1920` and keep aspect ratio

### `Pixel_Format`
Pixel format of video. Directly passed to ffmpeg as `pix_fmt`.
You'll need a custom built ffmpeg for encoding high-bitdepth video.

### `HDR`
Encode HDR video (ignored if `Video_Encode_Codec` not equals `x265`).
Both `MediaInfo` and `mujs` are required for HDR metadata parsing.

* Possible Values
    * `No`: Disable (Default)
    * `Auto`: Detect if source video is HDR and encode HDR video from HDR source
    * `Force`: Encode video as HDR whatever source (NOT recommended)

## Audio
### `Audio_Encode_Codec`
The codec for audio encoding.

* Possible Values
    * `opus` (Default)
    * `fdkaac` (Required a `fdkaac.exe` in `bin32` or `bin64`)
    * `none`: Disable audio encoding in video encoding.
    * `copy`: Try to remux audio without re-encoding.

### `Audio_Encode_Quality`
Quality for audio encoding.

* Possible Values: `1-5`, larger for better quality anf larger file size.
* Default Value: `3`

### `Audio_Encode_Profile`
Audio encoding Profile for `fdkaac`.

* Possible Values
    * `2`: MPEG-4 AAC LC (Default)
    * `5`: MPEG-4 HE-AAC (SBR)
    * `29`: MPEG-4 HE-AAC v2 (SBR+PS)
    * `23`: MPEG-4 AAC LD
    * `39`: MPEG-4 AAC ELD

### `Audio_Encode_Channels`
Channels of encoding result.

* Possible Values
    * `0`: Keep the same as source (Default)
    * `2`: Force 2 channels (Forced this when `Audio_Encode_Profile=29`)

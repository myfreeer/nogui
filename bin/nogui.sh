#!bash
# https://stackoverflow.com/a/14203146
for i in "$@"
do
  case $i in
    -b=*|--bin=*)
      BINARY_DIR="${i#*=}"
      shift # past argument=value
    ;;
    -l=*|--log=*|--logfile=*)
      LOGFILE="${i#*=}"
      shift # past argument=value
    ;;
    -i=*|--input=*)
      INPUT="${i#*=}"
      shift # past argument=value
    ;;
    -o=*|--output=*)
      OUTPUT="${i#*=}"
      shift # past argument=value
    ;;
    -p=*|--preset=*)
      PRESET="${i#*=}"
      shift # past argument=value
    ;;
    -s=*|--scale=*)
      scale="${i#*=}"
      shift # past argument=value
    ;;
    --hwaccel=*)
      HWACCEL="${i#*=}"
      shift # past argument=value
    ;;
    --autocrop)
      CROP="AUTO"
      shift # past argument with no value
    ;;
    -c=*|--crop=*)
      CROP="crop=${i#*=}"
      shift # past argument=value
    ;;
    -ve=*|--encoder=*|--vencoder=*)
      Video_Encoder="${i#*=}"
      shift # past argument=value
    ;;
    -crf=*|--crf=*)
      CRF="${i#*=}"
      shift # past argument=value
    ;;
    -vp=*|--vpreset=*)
      VPRESET="${i#*=}"
      shift # past argument=value
    ;;
    -va=*|--vparam=*)
      VPARAM="${i#*=}"
      shift # past argument=value
    ;;
    --pixfmt=*)
      PIXFMT="${i#*=}"
      shift # past argument=value
    ;;
    --hdr=*)
      HDR="${i#*=}"
      shift # past argument=value
    ;;
    -ae=*|--aencoder=*)
      Audio_Encoder="${i#*=}"
      shift # past argument=value
    ;;
    -aq=*|--aquality=*)
      AQUALITY="${i#*=}"
      shift # past argument=value
    ;;
    -ap=*|--aprofile=*)
      APROFILE="${i#*=}"
      shift # past argument=value
    ;;
    -ac=*|--achannels=*)
      ACHANNELS="${i#*=}"
      shift # past argument=value
    ;;
    -a)
      TYPE="AUDIO"
      shift # past argument with no value
    ;;
    -v)
      TYPE="VIDEO"
      shift # past argument with no value
    ;;
    *)
      # unknown option
    ;;
  esac
done

# Init
FFMPEG="${BINARY_DIR}/ffmpeg -hide_banner -sws_flags spline"
FDKAAC="${BINARY_DIR}/fdkaac"
MEDIAINFO="${BINARY_DIR}/MediaInfo"
MUJS="${BINARY_DIR}/mujs"
rm -rf tmp
sleep 0.01
mkdir -p tmp

# Hwaccel decoding for ffmpeg
if [[ ! "${HWACCEL}" == "" ]] ; then
  FFMPEG="${FFMPEG} -hwaccel ${HWACCEL}"
fi

# Default Values
# PRESET="${PRESET:-hq}"
TYPE="${TYPE:-VIDEO}"
HDR="${HDR:-No}"

# Prase Preset
case "${PRESET}" in
  hq|x265_opus_hq)
    Video_Encoder="${Video_Encoder:-x265}"
    Audio_Encoder="${Audio_Encoder:-opus}"
    VPRESET="${VPRESET:-slower}"
    PIXFMT="${PIXFMT:-yuv420p10le}"
    VPARAM="${VPARAM:-aq-mode=2:weightb=1:rc-lookahead=120:keyint=720:min-keyint=1}"
    CRF="${CRF:-18}"
    AQUALITY="${AQUALITY:-4}"
  ;;
  x265_fast)
    Video_Encoder="${Video_Encoder:-x265}"
    Audio_Encoder="${Audio_Encoder:-opus}"
    VPRESET="${VPRESET:-fast}"
    VPARAM="${VPARAM:-aq-mode=2:weightb=1:merange=16:keyint=720:min-keyint=1}"
    CRF="${CRF:-21}"
    AQUALITY="${AQUALITY:-2}"
  ;;
  sd|minisd)
    Video_Encoder="${Video_Encoder:-x264}"
    Audio_Encoder="${Audio_Encoder:-fdkaac}"
    VPRESET="${VPRESET:-veryslow}"
    VPARAM="${VPARAM:-bframes=16:weightb=1:keyint=720:min-keyint=1}"
    CRF="${CRF:-21}"
    AQUALITY="${AQUALITY:-3}"
    APROFILE="${APROFILE:-29}"
    ACHANNELS="${ACHANNELS:-2}"
    scale="${scale:-sd}"
  ;;
  *)
    Video_Encoder="${Video_Encoder:-x265}"
    Audio_Encoder="${Audio_Encoder:-opus}"
    VPRESET="${VPRESET:-slow}"
    VPARAM="${VPARAM:-aq-mode=2:weightb=1:rc-lookahead=120:keyint=720:min-keyint=1}"
    CRF="${CRF:-21}"
    AQUALITY="${AQUALITY:-3}"
  ;;
esac

if [[ ! "${scale}" == "" ]] ; then
  case $scale in
    hf|half|halfsize)
      SCALE="scale=iw*.5:ih*.5"
    ;;
    sd|480p)
      SCALE="scale=854:-2"
    ;;
    hd|720p)
      SCALE="scale=1280:-2"
    ;;
    fhd|1080p)
      SCALE="scale=1920:-2"
    ;;
    0|no|none)
      SCALE=
    ;;
    *)
      SCALE="scale=${scale}"
    ;;
  esac
fi

# Basic_tools

# https://unix.stackexchange.com/a/40897
# float number calc
calc() {
  awk "BEGIN{print $*}";
  return $?
}

# https://stackoverflow.com/a/965072
get_filename() {
  filename=$(basename "$*")
  # extension="${filename##*.}"
  echo "${filename%.*}"
}

# Audio encode tools
get_last_bitrate() {
  local input_file="$1"
  $FFMPEG -i "${input_file}" 2>&1 | awk '/bitrate: *[0-9]+ *kb\/s/ { print $(NF-1) }'
  return $?
}

encode_audio_vorbis() {
  if [[ "$1" == "2" ]] ; then
    local ac="-ac 2"
    shift
  fi
  local input_file="$1"
  local output_file="$2"
  output_file="${output_file:-tmp/$(get_filename "${input_file}")_vorbis.mka}"
  local quality="$3"
  quality="${quality:-4}"
  if [[ "$4" == "-b:a k" ]] ; then return 1 ; fi
  $FFMPEG -v error -i "${input_file}" -t 600 -vn -sn -dn $ac -c:a pcm_f32le -f wav - |\
  $FFMPEG -i - -vn -sn -dn -c:a libvorbis -q:a "${quality}" "${output_file}"
  return $?
}

encode_audio_fdk() {
  if [[ "${ACHANNELS}" == "2" ]] || [[ "${APROFILE}" == "29" ]] ; then
    local ac="-ac 2"
  fi
  local input_file="${INPUT}"
  local output_file="${OUTPUT}"
  output_file="${output_file:-tmp/$(get_filename "${input_file}")_fdkaac.m4a}"
  local quality="${AQUALITY:-3}"
  local profile="${APROFILE:-2}"
  # Profile (audio object type)
  #  2: MPEG-4 AAC LC (default)
  #  5: MPEG-4 HE-AAC (SBR)
  # 29: MPEG-4 HE-AAC v2 (SBR+PS)
  # 23: MPEG-4 AAC LD
  # 39: MPEG-4 AAC ELD
  $FFMPEG -v error -i "${input_file}" -vn -sn -dn $ac -c:a pcm_f32le -f caf - |\
  $FDKAAC - -p "${profile}" -m "${quality}" -I -o "${output_file}"
  return $?
}

encode_audio_bitrate() {
  local ac
  if [[ "$1" == "2" ]] ; then
    ac="-ac 2"
    shift
  else
    ac="-af aformat=channel_layouts=7.1|6.1|5.1|stereo|mono" # workaround for opus
  fi
  local input_file="$1"
  local output_file="$2"
  output_file="${output_file:-tmp/$(get_filename "${input_file}")_bitrate.mka}"
  local codec="$3"
  codec="${codec:-libopus}"
  local bitrate="-b:a $4k"
  if [[ "${bitrate}" == "-b:a k" ]] ; then return 1 ; fi
  $FFMPEG -v error -i "${input_file}" -vn -sn -dn $ac -c:a pcm_f32le -f wav - |\
  $FFMPEG -i - -vn -sn -dn -c:a "${codec}" $bitrate "${output_file}"
  return $?
}

encode_opus_by_quality() {
  if [[ "${ACHANNELS}" == "2" ]] ; then
    local ac="2"
  fi
  local input_file="${INPUT}"
  local input_filename="$(get_filename "${input_file}")"
  local tmp_file="tmp/${input_filename}_quality_tmp.mka"
  local output_file="${OUTPUT:-tmp/${input_filename}_opus.mka}"
  local quality="${AQUALITY:-4}"
  encode_audio_vorbis $ac "${input_file}" "${tmp_file}" "${quality}"
  local bitrate=$(get_last_bitrate "${tmp_file}")
  bitrate=$(($bitrate*3/4))
  encode_audio_bitrate $ac "${input_file}" "${output_file}" libopus "${bitrate}"
  if [[ $? == 0 ]] ; then rm -f "${tmp_file}" ; fi
  return $?
}

#encode_audio_fdk "${INPUT}" 1.m4a 3 29
#
#encode_opus_by_quality "${INPUT}"

# Video encode tools
crop_detect() {
  local input_file="$1"
  local start_time="$2"
  start_time="${start_time:-600}"
  local time_length="$3"
  time_length="${time_length:-120}"
  $FFMPEG -ss "${start_time}" -hwaccel auto -i "${input_file}" \
  -t "${time_length}" -sn -dn -an -vf cropdetect=24:2 \
  -f null null 2>&1 | awk '/crop/ { print $NF }' | tail -1
  return $?
}

create_vf() {
  local vf
  if [[ "${CROP}" == "AUTO" ]]; then
    (>&2 echo "Running crop-detect...")
    CROP=$(crop_detect "${INPUT}")
  fi
  if [[ ! "${CROP}" == "" ]] ; then
    if [[ ! "${SCALE}" == "" ]] ; then
      vf="-vf ${CROP},${SCALE}"
    else
      vf="-vf ${SCALE}"
    fi
    elif [[ ! "${SCALE}" == "" ]] ; then
    vf="-vf ${SCALE}"
  fi
  echo "${vf}"
}

create_cmdline() {
  local vf=$(create_vf)
  local cmdline=" "
  local my_vparam="${VPARAM}"
  if [[ ! "${vf}" == "" ]] ; then
    cmdline="${cmdline}${vf} "
  fi
  cmdline="${cmdline}-c:v lib${Video_Encoder} -crf ${CRF} "
  if [[ ! "${VPRESET}" == "" ]] ; then
    cmdline="${cmdline}-preset:v ${VPRESET} "
  fi
  if [[ ! "${PIXFMT}" == "" ]] ; then
    cmdline="${cmdline}-pix_fmt ${PIXFMT} "
  fi
  if [[ "${HDR}" == "Auto" ]] || [[ "${HDR}" == "Force" ]] ; then
    $MEDIAINFO --Output="Video;%colour_range%\n%transfer_characteristics%\n%colour_primaries%\n%matrix_coefficients%\n%MasteringDisplay_ColorPrimaries%\n%MasteringDisplay_Luminance%\n%MaxCLL%\n%MaxFALL%\n%ChromaSubsampling_Position%" "${INPUT}" > tmp/hdrinfo.txt
    hdrinfo=$($MUJS bin/parseHdrInfo.js)
    if [[ ! "${hdrinfo}" == "" ]] ; then
      hdrinfo="hdr=1:hdr-opt=1:${hdrinfo}"
    elif [[ "${HDR}" == "Force" ]] ; then
      hdrinfo="hdr=1:hdr-opt=1"
    fi
    if [[ "${Video_Encoder}" == "x265" ]] && [[ ! "${hdrinfo}" == "" ]] ; then
      my_vparam="\"${hdrinfo}:${my_vparam}\""
    fi
  fi
  if [[ ! "${my_vparam}" == "" ]] ; then
    cmdline="${cmdline}-${Video_Encoder}-params ${my_vparam} "
  fi
  echo "${cmdline}"
}

encode_video_opus() {
  local af
  local ac
  if [[ "${ACHANNELS}" == "2" ]] ; then
    af="-af pan=stereo|FL=FL+0.707107FC+0.707107BL+0.707107SL|FR=FR+0.707107FC+0.707107BR+0.707107SR"
    ac=2
  else
    af="-af aformat=channel_layouts=7.1|6.1|5.1|stereo|mono" # workaround for opus
  fi
  local input_file="$1"
  local input_filename="$(get_filename "${input_file}")"
  local output_file="$2"
  local tmp_file="tmp/${input_filename}_quality_tmp.mka"
  local bitrate
  encode_audio_vorbis $ac "${input_file}" "${tmp_file}" "${AQUALITY}"
  local bitrate=$(get_last_bitrate "${tmp_file}")
  bitrate=$(($bitrate*3/4))
  local cmdline="$(create_cmdline)"
  if [[ ! "${af}" == "" ]] ; then
    cmdline="${cmdline} -map 0:a:0 ${af}"
  fi
  cmdline="${cmdline} -c:a lib${Audio_Encoder} -b:a ${bitrate}k "
  $FFMPEG -i "${input_file}" -map 0:v:? $cmdline -c:s copy "${output_file}"
  if [[ $? == 0 ]] ; then rm -f "${tmp_file}" ; fi
  return $?
}
# encode_video_opus "${INPUT}" 1.mkv

encode_video_fdk() {
  if [[ "${ACHANNELS}" == "2" ]] || [[ "${APROFILE}" == "29" ]] ; then
    local ac="-ac 2"
  fi
  local input_file="$1"
  local input_filename="$(get_filename "${input_file}")"
  local output_file="$2"
  local cmdline="$(create_cmdline)"
  $FFMPEG -v error -i "${input_file}" -vn -sn -dn -map 0:a:0 $ac -c:a pcm_f32le -f caf - |\
    $FDKAAC - -p "${APROFILE:-2}" -m "${AQUALITY:-3}" -I -f 2 -S -C -o - |\
    $FFMPEG -i "${input_file}" -i - -map 0:v? $cmdline -map 1:a -c:a copy -map 0:s? -c:s copy "${output_file}"
  return $?
}
# encode_video_fdk "${INPUT}" 1.mkv

main() {
  if [[ "${TYPE}" == "VIDEO" ]] ; then
    if [[ "${Audio_Encoder}" == "opus" ]] || [[ "${Audio_Encoder}" == "libopus" ]] ; then
      encode_video_opus "${INPUT}" "${OUTPUT}"
    else #fdk
      encode_video_fdk "${INPUT}" "${OUTPUT}"
    fi #Audio_Encoder
  else # $TYPE=AUDIO
    if [[ "${Audio_Encoder}" == "opus" ]] || [[ "${Audio_Encoder}" == "libopus" ]] ; then
      encode_opus_by_quality $ACHANNELS "${INPUT}" "${OUTPUT}" "${AQUALITY}"
    else #fdk
      encode_audio_fdk $ACHANNELS "${INPUT}" "${OUTPUT}" "${AQUALITY:-3}" "${APROFILE}"
    fi #Audio_Encoder
  fi #TYPE
}

if [[ "${LOGFILE}" == "" ]] ; then
  main
else # have $LOGFILE
  main 2>&1 | tee -a "${LOGFILE}"
fi #logfile

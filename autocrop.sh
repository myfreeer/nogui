#!sh
./ffmpeg -ss 600 -i $1 -t 120 -sn -dn -an -vf cropdetect=24:2 -f null nul 2>&1 | awk '/crop/ { print $NF }' | tail -1
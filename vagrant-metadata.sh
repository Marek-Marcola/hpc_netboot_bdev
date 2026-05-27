#!/bin/bash

BDIR=""
NAME=""
DESC=""
BURL=""
ARGS=""
CONV=cat
HELP=0

while [ $# -gt 0 ]
do
  case $1 in
    -D)
      BDIR="$2"
      shift;shift
      ;;
    -n)
      NAME="$2"
      shift;shift
      ;;
    -d)
      DESC="$2"
      shift;shift
      ;;
    -u)
      BURL="$2"
      shift;shift
      ;;
    -j)
      CONV="yq -o=json"
      shift;shift
      ;;
    -h|-help|--help)
      HELP=1
      shift
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

if [ $HELP -eq 1 -o "$BDIR" = "" ]; then
  echo "$(basename $0) -D bdir [-n name] [-d desc] [-u burl] [-j]"
  exit 0
fi

if [ "$NAME" = "" ]; then
  NAME=$(basename $BDIR)
fi
if [ "$DESC" = "" ]; then
  DESC=$NAME
fi
if [ "$BURL" = "" ]; then
  BURL=http://repo/sw/linux/vagrant
fi

cd $BDIR || exit 1

(
echo name: $NAME
echo description: $DESC
echo versions:

ls *.txt | \
while read T; do
  C=$(cat $T|awk '{print $1}')
  F=$(cat $T|awk '{print $2}')
  V=$(echo $F|awk -F- '{print $2}')
  P=$(echo $F|awk -F- '{print $4}'|awk -F. '{print $1}')

  echo "  - version: \"$V\""
  echo "    providers:"
  echo "      - name: $P"
  echo "        url: $BURL/$NAME/$F"
  echo "        checksum_type: sha1"
  echo "        checksum: $C"
done
) | $CONV

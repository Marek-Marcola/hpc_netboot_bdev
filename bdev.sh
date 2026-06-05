#!/bin/bash

VERSION_BIN="260605"

SN="${0##*/}"
ID="[$SN]"

DEBUG=0

EFILE=""
REPO=""

: ${PKR_VAR_os_id:=""}
: ${PKR_VAR_os_from:=""}
: ${PKR_VAR_os_ver:=""}
: ${PKR_VAR_os_maj:=""}
: ${PKR_VAR_os_tag:=""}
: ${PKR_VAR_os_web:=""}
: ${PKR_VAR_os_out:=""}
: ${PKR_VAR_os_anpb:=""}
: ${PKR_VAR_os_date:=""}

INSTALL_RSYNC=0
INSTALL_ANPB=0
INSTALL_ANPB_HP="bdev"
VERSION=0
STAGE_LIST=0
PLUGINS=0
ENV=0
LIST=0
CLEAN=0
INSPECT=0
VALIDATE=0
BUILD=0
BUILDF=0
EXPORT_CREATE=0
EXPORT_UPLOAD=0
CHAIN=0
FILES=0
HELP=0
QUIET=0

declare -a ARGS1

ls | grep -q pkr.hcl
[[ $? -eq 0 ]] && REPO="$(basename $(pwd))"

: ${COMM:=$(readlink -f ${BASH_SOURCE})}

while [ $# -gt 0 ]; do
  case $1 in
    --vers*|-vers*)
      VERSION=1
      shift
      ;;
    --inst*|-inst*)
      INSTALL_RSYNC=1
      shift
      ;;
    --anpb|-anpb)
      INSTALL_ANPB=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && INSTALL_ANPB_HP="$2" && shift
      shift
      ;;
    --stage|-stage)
      STAGE_LIST=1
      shift
      ;;
    -P)
      PLUGINS=1
      shift
      ;;
    -E)
      ENV=1
      shift
      ;;
    -l)
      LIST=1
      shift
      ;;
    -c)
      CLEAN=1
      shift
      ;;
    -i)
      INSPECT=1
      shift
      ;;
    -v)
      VALIDATE=1
      shift
      ;;
    -b)
      BUILD=1
      shift
      ;;
    -bf)
      BUILDF=1
      shift
      ;;
    -e)
      EXPORT_CREATE=1
      shift
      ;;
    -eu)
      EXPORT_UPLOAD=1
      shift
      ;;
    -ic)
      CHAIN=1
      shift
      ;;
    -iv)
      CHAIN=2
      shift
      ;;
    -if)
      FILES=1
      QUIET=1
      shift
      ;;
    -R)
      REPO="$2"
      shift; shift
      ;;
    -I)
      PKR_VAR_os_id="$2"
      shift; shift
      ;;
    -F)
      PKR_VAR_os_from="$2"
      shift; shift
      ;;
    -V)
      PKR_VAR_os_ver="$2"
      shift; shift
      ;;
    -T)
      PKR_VAR_os_tag="$2"
      shift; shift
      ;;
    -W)
      PKR_VAR_os_web="$2"
      shift; shift
      ;;
    -O)
      PKR_VAR_os_out="$2"
      shift; shift
      ;;
    -A)
      PKR_VAR_os_anpb="$2"
      shift; shift
      ;;
    -d)
      PKR_VAR_os_date="$2"
      shift; shift
      ;;
    -D)
      DEBUG=1
      shift
      ;;
    -h|-help|--help)
      HELP=1
      shift
      ;;
    -q)
      QUIET=1
      shift
      ;;
    *)
      ARGS1+=("$1")
      shift
      ;;
  esac
done

#
# stage: HELP
#
if [ $HELP -eq 1 ]; then
  echo "$SN -version                       # version"
  echo "$SN -install                       # install with rsync"
  echo "$SN -anpb [host_pattern] [-x]      # install with ansible"
  echo "$SN -stage                         # stage list"
  echo ""
  echo "$SN -P                             # plugins"
  echo "$SN -E  [opts]                     # env"
  echo "$SN -l  [opts]                     # list"
  echo "$SN -c  [opts]                     # clean"
  echo "$SN -i  [opts]                     # inspect"
  echo "$SN -v  [opts]                     # validate"
  echo "$SN -b  [opts]                     # build"
  echo "$SN -bf [opts]                     # build from list"
  echo "$SN -e  [opts]                     # export create"
  echo "$SN -eu [opts]                     # export upload"
  echo "$SN -ic                            # image chain"
  echo "$SN -iv                            # image versions"
  echo "$SN -if                            # image files"
  echo "$SN                                # info"
  echo ""
  echo "opts:"
  echo "  -R repo"
  echo "  -I id"
  echo "  -F from"
  echo "  -V ver"
  echo "  -T tag"
  echo "  -W web"
  echo "  -O out"
  echo "  -A anpb"
  echo "  -d date"
  echo ""
  echo "env files: \$HOME/.bdev.env .bdev.env \$PDEVENV /usr/local/etc/bdev.env"
  echo ""
  echo "notes"
  echo "  sha1sum linux.iso > linux.txt"
  echo ""
  echo "  vncviewer -shared 127.0.0.1:59xx"
  echo "  virt-tar-out -a disk.qcow2 / - | tar tvf -"
  echo "  virt-cat -a disk.qcow2 /etc/passwd"
  exit 0
fi

#
# stage: CONFIG
#
for f in $HOME/.bdev.env .bdev.env $PDEVENV /usr/local/etc/bdev.env; do
  if [ -e $f ]; then
    [[ "$EFILE" != "" ]] && EFILE="$EFILE $f" || EFILE="$f"
    . $f
  fi
done

: ${PKR_VAR_os_maj:=$(echo $PKR_VAR_os_ver|awk -F. '{print $1}')}
: ${PKR_VAR_os_img:=$PKR_VAR_os_out/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$PKR_VAR_os_id/$PKR_VAR_os_dist-$PKR_VAR_os_ver-x86_64.qcow2}
: ${PKR_VAR_os_iso:=$PKR_VAR_os_out/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$PKR_VAR_os_from/$PKR_VAR_os_dist-$PKR_VAR_os_ver-x86_64.qcow2}
: ${PKR_VAR_os_sum:=$(echo $PKR_VAR_os_iso|sed -e 's/iso$/txt/' -e 's/qcow2$/txt/')}
: ${PKR_VAR_os_date:=$(date +%Y%m%d%H%M)}
: ${PKR_VAR_os_edir:=$PKR_VAR_os_out/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$PKR_VAR_os_id}
: ${PKR_VAR_vg_repo:=$PKR_VAR_os_dist$PKR_VAR_os_maj-$PKR_VAR_os_from}

DFILE=$PKR_VAR_os_out/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$PKR_VAR_os_id/$PKR_VAR_os_dist-$PKR_VAR_os_ver-x86_64.date

if [ -f $DFILE ]; then
  PKR_VAR_os_etar=$PKR_VAR_os_edir/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$(cat $DFILE|head -1|awk '{print $1}').tar
else
  PKR_VAR_os_etar=$PKR_VAR_os_edir/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$PKR_VAR_os_date.tar
fi

os_img_size="-"
os_iso_size="-"
os_sum_size="-"

if [ -f "$PKR_VAR_os_img" ]; then
  os_img_size=$(ls -lhH $PKR_VAR_os_img|awk '{print $5}')
fi
if [ -f "$PKR_VAR_os_iso" ]; then
  os_iso_size=$(ls -lhH $PKR_VAR_os_iso|awk '{print $5}')
fi
if [ -f "$PKR_VAR_os_sum" ]; then
  os_sum_size=$(ls -lhH $PKR_VAR_os_sum|awk '{print $5}')
fi

export PKR_VAR_os_id
export PKR_VAR_os_from
export PKR_VAR_os_dist
export PKR_VAR_os_ver
export PKR_VAR_os_maj
export PKR_VAR_os_tag
export PKR_VAR_os_web
export PKR_VAR_os_out
export PKR_VAR_os_img
export PKR_VAR_os_iso
export PKR_VAR_os_sum
export PKR_VAR_os_anpb
export PKR_VAR_os_date
export PKR_VAR_os_edir
export PKR_VAR_os_etar
export PKR_VAR_vg_repo

#
# stage: VERSION
#
if [ $VERSION -eq 1 ]; then
  echo "${0##*/}  $VERSION_BIN"
  [[ "$VERSION_ENV" != "" ]] && echo "bdev.env $VERSION_ENV"
  if [ $(type -t packer) ]; then
    set -ex
    packer --version
    packer plugins installed
    { set +ex; } 2>/dev/null
  fi
  exit 0
fi

#
# stage: INSTALL-RSYNC
#
if [ $INSTALL_RSYNC -eq 1 ]; then
  if [ -f bdev.env ]; then
    for d in /usr/local/etc /pub/pkb/kb/data/999202-bdev/999202-000020_bdev_script /pub/pkb/pb/playbooks/999202-bdev/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai bdev.env $d
        { set +ex; } 2>/dev/null
      fi
    done
  fi
  if [ -f bdev.sh ]; then
    for d in /usr/local/bin /pub/pkb/kb/data/999202-bdev/999202-000020_bdev_script /pub/pkb/pb/playbooks/999202-bdev/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai bdev.sh $d
        { set +ex; } 2>/dev/null
      fi
    done
  fi
  if [ -f vagrant-metadata.sh ]; then
    for d in /usr/local/bin /pub/pkb/kb/data/999202-bdev/999202-000020_bdev_script /pub/pkb/pb/playbooks/999202-bdev/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai vagrant-metadata.sh $d
        { set +ex; } 2>/dev/null
      fi
    done
  fi
  exit 0
fi

#
# stage: INSTALL-ANPB
#
if [ $INSTALL_ANPB -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INSTALL-ANPB (EVAL=$EVAL)"

  if [ ! $(type -t anpb) ]; then
    echo "$ID: error: command not found: anpb"
    exit 1
  fi

  [[ $EVAL -ne 1 ]] && EVAL_OPT="--check --diff" || EVAL_OPT=""

  set -ex
  anpb bdev_install.yml -e h=$INSTALL_ANPB_HP $EVAL_OPT
  { set +ex; } 2>/dev/null

  exit 0
fi

#
# stage: STAGE-LIST
#
if [ $STAGE_LIST -eq 1 ]; then
  cat $COMM | grep '^#' | grep 'stage:'
  exit 0
fi

#
# stage: INFO
#
if [ $QUIET -eq 0 ]; then
  echo "$ID: stage: INFO"

  [[ -n $INFO ]] && echo "info    = ${INFO}"
  echo "cwd     = $(pwd -P)"
  echo "efile   = ${EFILE:-[none]}"
  echo "repo    = ${REPO:-[none]}"
  echo "os_id   = ${PKR_VAR_os_id:-[none]}"
  echo "os_from = ${PKR_VAR_os_from:-[none]}"
  echo "os_dist = ${PKR_VAR_os_dist:-[none]}"
  echo "os_ver  = ${PKR_VAR_os_ver:-[none]}"
  echo "os_maj  = ${PKR_VAR_os_maj:-[none]}"
  echo "os_tag  = ${PKR_VAR_os_tag:-[none]}"
  echo "os_web  = ${PKR_VAR_os_web:-[none]}"
  echo "os_out  = ${PKR_VAR_os_out:-[none]}"
  echo "os_img  = ${PKR_VAR_os_img:-[none]} ($os_img_size)"
  echo "os_iso  = ${PKR_VAR_os_iso:-[none]} ($os_iso_size)"
  echo "os_sum  = ${PKR_VAR_os_sum:-[none]} ($os_sum_size)"
  echo "os_anpb = ${PKR_VAR_os_anpb:-[none]}"
  echo "os_date = ${PKR_VAR_os_date:-[none]}"
  echo "os_edir = ${PKR_VAR_os_edir:-[none]}"
  echo "os_etar = ${PKR_VAR_os_etar:-[none]}"
  echo "os_eurl = ${PKR_VAR_os_eurl:-[none]}"
  echo "vg_burl = ${PKR_VAR_vg_burl:-[none]}"
  echo "vg_bdir = ${PKR_VAR_vg_bdir:-[none]}"
  echo "vg_repo = ${PKR_VAR_vg_repo:-[none]}"
  echo "vm_cpu  = ${PKR_VAR_vm_cpu:-[none]}"
  echo "vm_mem  = ${PKR_VAR_vm_mem:-[none]}"
  echo "vm_disk = ${PKR_VAR_vm_disk:-[none]}"

  if [ "$DOCS" != "" ]; then
    echo -n "docs    = "
    echo "$DOCS" | sed 's/\!/\n/g' | sed '2,$ s/^/         /'
  fi
fi

#
# stage: PLUGINS
#
if [ $PLUGINS -ne 0 ]; then
  echo -e "\n$ID: stage: PLUGINS"

  set -ex
  packer plugins installed
  { set +ex; } 2>/dev/null
fi

#
# stage: ENV
#
if [ $ENV -ne 0 ]; then
  echo -e "\n$ID: stage: ENV"

  env | grep -e CHECKPOINT_DISABLE -e PACKER -e PKR | sort
fi

#
# stage: LIST
#
if [ $LIST -ne 0 ]; then
  echo -e "\n$ID: stage: LIST"

  if [ -d $PKR_VAR_os_out/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$PKR_VAR_os_id ]; then
    set -ex
    ls -lh $PKR_VAR_os_out/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$PKR_VAR_os_id
    { set +ex; } 2>/dev/null
  fi
fi

#
# stage: CLEAN
#
if [ $CLEAN -ne 0 ]; then
  echo -e "\n$ID: stage: CLEAN"

  set -x
  rm -fv $PKR_VAR_os_out/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$PKR_VAR_os_id/$PKR_VAR_os_dist-$PKR_VAR_os_ver-x86_64*
  rm -fv $PKR_VAR_os_out/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$PKR_VAR_os_id/$PKR_VAR_os_dist-$PKR_VAR_os_ver-*.tar
  { set +ex; } 2>/dev/null

  if [ -d $PKR_VAR_os_out/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$PKR_VAR_os_id ]; then
    set -x
    rmdir -v $PKR_VAR_os_out/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$PKR_VAR_os_id
    { set +ex; } 2>/dev/null
  fi
fi

#
# stage: INSPECT
#
if [ $INSPECT -ne 0 ]; then
  echo -e "\n$ID: stage: INSPECT"

  set -ex
  packer inspect .
  { set +ex; } 2>/dev/null
fi

#
# stage: VALIDATE
#
if [ $VALIDATE -ne 0 ]; then
  echo -e "\n$ID: stage: VALIDATE"

  set -ex
  packer validate .
  { set +ex; } 2>/dev/null
fi

#
# stage: BUILD
#
if [ $BUILD -ne 0 ]; then
  echo -e "\n$ID: stage: BUILD"

  set -ex
  packer build .
  { set +ex; } 2>/dev/null

  echo

  set -ex
  ls -lh $PKR_VAR_os_out/$PKR_VAR_os_dist-$PKR_VAR_os_ver-$PKR_VAR_os_id
  { set +ex; } 2>/dev/null
fi

#
# stage: BUILDF
#
if [ $BUILDF -ne 0 ]; then
  echo -e "\n$ID: stage: BUILDF"

  R=$REPO

  if [ "$R" != "" ]; then
    echo "$R"
    F=$(bdev.sh -R $R|grep os_from|awk '{print $3}')
    R=$(echo $R|awk -F- -v F=$F '{printf "%s-%s-%s",$1,$2,F}')
    echo " - $F"

    while [[ ! $F =~ none ]]; do
      F=$(bdev.sh -R $R|grep os_from|awk '{print $3}')
      R=$(echo $R|awk -F- -v F=$F '{printf "%s-%s-%s",$1,$2,F}')
      if [[ ! $F =~ none ]]; then
        echo " - $F"
      fi
    done
  fi
fi

#
# stage: EXPORT_CREATE
#
if [ $EXPORT_CREATE -ne 0 ]; then
  echo -e "\n$ID: stage: EXPORT CREATE"

  set -ex
  export LIBGUESTFS_BACKEND=direct
  cp -pv ${PKR_VAR_os_img} ${PKR_VAR_os_img}.tmp
  virt-sysprep -a ${PKR_VAR_os_img}.tmp --operation defaults,-machine-id --hostname localhost
  virt-tar-out -a ${PKR_VAR_os_img}.tmp / $PKR_VAR_os_etar
  rm -fv ${PKR_VAR_os_img}.tmp
  { set +ex; } 2>/dev/null
fi

#
# stage: EXPORT_UPLOAD
#
if [ $EXPORT_UPLOAD -ne 0 ]; then
  echo -e "\n$ID: stage: EXPORT UPLOAD"

  if [ -f "$PKR_VAR_os_etar" ]; then
    SCP_OPTS="-q -B -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
    for url in $PKR_VAR_os_eurl; do
      set -ex
      scp $SCP_OPTS $PKR_VAR_os_etar $url
      { set +ex; } 2>/dev/null
    done
  else
    echo $ID: export file not found: $PKR_VAR_os_etar
  fi
fi

#
# stage: CHAIN
#
if [ $CHAIN -ne 0 ]; then
  echo -e "\n$ID: stage: CHAIN"

  if [ -f "$PKR_VAR_os_img" ]; then
    if [ "$CHAIN" = "1" ]; then
      virt-tar-out -a $PKR_VAR_os_img /version.d - | tar xOvf - 2>&1 | grep -E 'date|name|from' | \
        sed -e 's/info.name/ID/' -e 's/info.from/FROM/' -e 's/info.date//' -e 's/ //g' -e 's/^=//' | \
        sed 'N;s/\n/ /;N;s/\n/ /' | column -t | sort -nr
    else
      virt-tar-out -a $PKR_VAR_os_img /version.d - | tar xOvf - 2>&1 | \
        sed -e 's/^i/  i/' -e 's|\./||' -e 's/^/  /' -e 's/^  $/version:/' -e 's|version-|/version.d/version-|';
    fi
  else
    echo "$ID: error: access: $PKR_VAR_os_img"
  fi
fi

#
# stage: FILES
#
if [ $FILES -ne 0 ]; then
  echo -e "\n$ID: stage: FILES"

  if [ -f "$PKR_VAR_os_img" ]; then
    virt-tar-out -a $PKR_VAR_os_img / - | tar tvf - 2>&1
  else
    echo "$ID: error: access: $PKR_VAR_os_img"
  fi
fi

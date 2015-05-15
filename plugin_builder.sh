#!/bin/bash

while getopts "n:s:t:b:m:d:" opt; do
  case "$opt" in
  n)
    name="${OPTARG}"    ;;
  s)
    src="${OPTARG}"     ;;
  t)
    target="${OPTARG}"  ;;
  b)
    build="${OPTARG}"   ;;
  m)
    mysrc="${OPTARG}"   ;;
  d)
    ver="${OPTARG}"     ;;
  *)
    usage               ;;
  esac
done

src="${src:-./$name}"
target="${target:-.}"
build="${build:-mysql_release}"
mysrc="${mysrc:-$target/mysql-$ver}"
target="$(readlink -e "$target")"


usage() {
  echo "usage: $0 (-d <download mysql version> | -m <mysql source>) -n <plugin name> [-t <target> -b <build> -s <plugin source>]" >&2
  exit 1
}

if [[ -z "$name" ]]; then
  usage
fi

if [[ -z "$mysrc" ]]; then
  echo "mysql source not exists"
  if [[ -z "$ver" ]]; then
    usage
  fi
  file="mysql-$ver.tar.gz"
  if [[ ! -e "$file" ]]; then
    wget "http://downloads.mysql.com/archives/get/file/$file"
  fi
  tar -xzvf "$file"
fi

if [[ ! -e "mysql-$ver/plugin/${name}" ]]; then
  cp -r "$src" "mysql-$ver/plugin/${name}"
fi
cd "$mysrc"
if [[ ! -e plugin/${name}/${name}.so ]]; then
  cmake . -DBUILD_CONFIG="${build}"
  ncpu=$( grep "processor" /proc/cpuinfo | wc -l )
  (( nproc=$ncpu*2 ))
  make -j $nproc "${name}"
fi
my_ver=$(gawk -F'[()" ]+' '$1=="SET"&&$2=="CPACK_PACKAGE_FILE_NAME"{print $3}' "CPackConfig.cmake")
ver="${my_ver#*-}"
cp plugin/${name}/${name}.so "$target/${name}_${ver}.so"



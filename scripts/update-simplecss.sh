#!/bin/sh
#/ update-simplecss $version

set -eo pipefail

. "$(dirname "$0")/lib/include.sh"

version="$1"
if [ -z "${version}" ]; then
    usage 1
fi

set -xu

rootdir=$(absdir "$(absdir "$0")/../..")
mkdir -p "${rootdir}/assets/css"
curl -so "${rootdir}/assets/css/simplecss.min.css" "https://raw.githubusercontent.com/kevquirk/simple.css/${version}/simple.min.css"
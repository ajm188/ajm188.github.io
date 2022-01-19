function usage() {
    local code=$1
    cat "$0" | grep -E "^#/ " | sed 's:^#/ ::' >&2
    exit $code
}

###
# absdir returns the absolute path to the directory containing $1.
#
# Note: requires realpath to be installed. On macOS, `brew install coreutils`.
###
function absdir() {
    realpath "$(dirname "$1")"
}

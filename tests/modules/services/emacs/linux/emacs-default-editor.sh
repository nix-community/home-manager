set +u
source $TESTED/home-path/etc/profile.d/hm-session-vars.sh
set -u

check_arguments () {
    if [ "$1" != "$2" ]; then
	@coreutils@/bin/cat <<- EOF
	Expected arguments:
	$1
	but got:
	$2
	EOF
	exit 1
    fi
}

check_arguments "--create-frame" "$($EDITOR)"
check_arguments "foo bar baz" "$($EDITOR foo bar baz)"

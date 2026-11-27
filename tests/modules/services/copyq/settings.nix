{
  config,
  lib,
  realPkgs,
  ...
}:
let
  # - $COPYQ_STATE/running exists when the server is running
  # - $COPYQ_STATE/config contains the set options, one per line
  # - commands fail when it is not running
  fakeCopyq = realPkgs.writeShellScriptBin "copyq" ''
    if [[ $1 == --start-server ]]; then
      shift
      touch "$COPYQ_STATE/running"
    fi
    [[ -e $COPYQ_STATE/running ]] || exit 1
    case $1 in
      exit) rm "$COPYQ_STATE/running" ;;
      config)
        shift
        while (( $# )); do
          echo "$1 $2" >> "$COPYQ_STATE/config"
          shift 2
        done
        ;;
    esac
  '';

  activationSnippet = realPkgs.writeText "copyq-activation" config.home.activation.copyqConfig.data;
in
{
  services.copyq = {
    enable = true;
    package = fakeCopyq;
    settings = {
      hide_tabs = true;
      autostart = false;
    };
  };

  nmt.script = ''
    runActivation() {
      COPYQ_STATE=$1 \
        ${lib.getExe realPkgs.bash} -euo pipefail -c '
        run() { [[ $1 == --quiet ]] && shift; "$@"; }
        source ${activationSnippet}
      '
    }

    assertSettingsApplied() {
      if [[ $(sort "$1/config") != $'autostart false\nhide_tabs true' ]]; then
        fail "Settings not applied, got: $(cat "$1/config")"
      fi
    }

    # Case 1: server was not started
    state=$(mktemp -d)
    runActivation "$state"
    assertSettingsApplied "$state"
    if [[ -e $state/running ]]; then
      fail "Activation didn't stop the server it started"
    fi

    # Case 2: server was already started
    state=$(mktemp -d)
    touch "$state/running"
    runActivation "$state"
    assertSettingsApplied "$state"
    if [[ ! -e $state/running ]]; then
      fail "Activation stopped the server which was already started"
    fi
  '';
}

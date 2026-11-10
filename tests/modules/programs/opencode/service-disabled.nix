{
  config,
  lib,
  pkgs,
  ...
}:
let
  jq = lib.getExe pkgs.jq;
  testOpencode = import ./service-test-opencode.nix { inherit pkgs; };

  activationScript = pkgs.writeScript "opencode-service-activation" ''
    set -eu
    ${config.home.activation.opencodeServiceSettings.data}
  '';

  expected = builtins.toFile "opencode-service-disabled.json" (
    builtins.toJSON {
      disabled = true;
      hostname = "0.0.0.0";
      password = "app-generated";
      remote.route = "https://remote.example";
    }
  );
in
{
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  programs.opencode = {
    enable = true;
    package = testOpencode;

    service = {
      enable = true;
      settings.disabled = true;
    };
  };

  nmt.script = ''
    export HOME=$TMPDIR/hm-user
    export XDG_CONFIG_HOME=$HOME/.config
    export OPENCODE_TEST_LOG=$TMPDIR/opencode.log
    export OPENCODE_TEST_STATUS=$TMPDIR/opencode.status

    mkdir -p "$HOME/.config/opencode"
    cat > "$HOME/.config/opencode/service.json" <<'EOF'
    {
      "disabled": false,
      "hostname": "0.0.0.0",
      "password": "app-generated",
      "remote": {
        "route": "https://remote.example"
      }
    }
    EOF

    substitute ${activationScript} $TMPDIR/opencode-service-activate --subst-var TMPDIR
    chmod +x $TMPDIR/opencode-service-activate

    function run() { "$@"; }
    function verboseEcho() { printf 'VERBOSE: %s\n' "$*"; }
    function errorEcho() { printf 'ERROR: %s\n' "$*" >&2; }
    function assertJsonEqual() {
      diff -u <(${jq} --sort-keys . "$1") <(${jq} --sort-keys . "$2") \
        || fail "JSON content mismatch"
    }

    printf 'http://127.0.0.1:4096\n' > "$OPENCODE_TEST_STATUS"
    : > "$OPENCODE_TEST_LOG"

    ( source $TMPDIR/opencode-service-activate )
    assertJsonEqual "$HOME/.config/opencode/service.json" ${expected}
    [[ "$(stat -c '%a' "$HOME/.config/opencode/service.json")" == 600 ]] \
      || fail "The service configuration must have mode 600"
    grep -qx 'service status' "$OPENCODE_TEST_LOG" \
      || fail "A disabled service must check whether it is running"
    grep -qx 'service stop' "$OPENCODE_TEST_LOG" \
      || fail "A disabled service must be stopped"
    if grep -qx 'service restart' "$OPENCODE_TEST_LOG"; then
      fail "A disabled service must not be restarted"
    fi

    # A second activation leaves the already stopped service alone.
    : > "$OPENCODE_TEST_LOG"
    ( source $TMPDIR/opencode-service-activate )
    grep -qx 'service status' "$OPENCODE_TEST_LOG" \
      || fail "A disabled service must check whether it is running"
    if grep -qx 'service stop' "$OPENCODE_TEST_LOG"; then
      fail "An already stopped service must not be stopped again"
    fi
    if grep -qx 'service restart' "$OPENCODE_TEST_LOG"; then
      fail "A disabled service must not be restarted"
    fi
  '';
}

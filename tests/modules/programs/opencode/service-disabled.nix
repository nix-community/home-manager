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

    # Status reports stopped when discovery fails its health check, but the
    # registered service may still be running.
    printf 'stopped\n' > "$OPENCODE_TEST_STATUS"
    : > "$OPENCODE_TEST_LOG"

    ( source $TMPDIR/opencode-service-activate )
    assertJsonEqual "$HOME/.config/opencode/service.json" ${expected}
    [[ "$(stat -c '%a' "$HOME/.config/opencode/service.json")" == 600 ]] \
      || fail "The service configuration must have mode 600"
    grep -qx 'service stop' "$OPENCODE_TEST_LOG" \
      || fail "A disabled service must be stopped"
    if grep -qx 'service status' "$OPENCODE_TEST_LOG"; then
      fail "Stopping a disabled service must not depend on its health check"
    fi
    if grep -qx 'service restart' "$OPENCODE_TEST_LOG"; then
      fail "A disabled service must not be restarted"
    fi

    # Stopping is idempotent; a second activation still requests a stop.
    : > "$OPENCODE_TEST_LOG"
    ( source $TMPDIR/opencode-service-activate )
    grep -qx 'service stop' "$OPENCODE_TEST_LOG" \
      || fail "A disabled service must still request a stop"
    if grep -qx 'service status' "$OPENCODE_TEST_LOG"; then
      fail "Stopping a disabled service must not depend on its health check"
    fi
    if grep -qx 'service restart' "$OPENCODE_TEST_LOG"; then
      fail "A disabled service must not be restarted"
    fi
  '';
}

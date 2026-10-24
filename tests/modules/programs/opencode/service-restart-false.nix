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

  expected = builtins.toFile "opencode-service-restart-false.json" (
    builtins.toJSON {
      env.APP_ONLY = "yes";
      port = 4096;
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
      restartOnChange = false;
      settings.port = 4096;
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
      "port": 9999,
      "remote": {
        "route": "https://remote.example"
      },
      "env": {
        "APP_ONLY": "yes"
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
    if [[ -s "$OPENCODE_TEST_LOG" ]]; then
      fail "restartOnChange = false must not query or restart the service"
    fi
  '';
}

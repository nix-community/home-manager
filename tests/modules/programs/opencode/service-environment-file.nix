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

  # Declaring environmentFile owns the env object, so the app-owned APP_ONLY
  # entry is intentionally replaced.
  expected = builtins.toFile "opencode-service-environment-file.json" (
    builtins.toJSON {
      env = {
        FROM_FILE = "file";
        SHARED = "file";
      };
      password = "app-generated";
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
      environmentFile = "/@TMPDIR@/secrets/environment";
      settings.port = 4096;
    };
  };

  nmt.script = ''
    export HOME=$TMPDIR/hm-user
    export XDG_CONFIG_HOME=$HOME/.config
    export OPENCODE_TEST_LOG=$TMPDIR/opencode.log
    export OPENCODE_TEST_STATUS=$TMPDIR/opencode.status

    mkdir -p "$HOME/.config/opencode" "$TMPDIR/secrets"
    printf 'SHARED=file\nFROM_FILE=file\n' > "$TMPDIR/secrets/environment"
    cat > "$HOME/.config/opencode/service.json" <<'EOF'
    {
      "port": 9999,
      "password": "app-generated",
      "remote": {
        "route": "https://remote.example"
      },
      "env": {
        "APP_ONLY": "yes",
        "SHARED": "app"
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

    printf 'stopped\n' > "$OPENCODE_TEST_STATUS"
    : > "$OPENCODE_TEST_LOG"

    ( source $TMPDIR/opencode-service-activate )
    assertJsonEqual "$HOME/.config/opencode/service.json" ${expected}
    [[ "$(stat -c '%a' "$HOME/.config/opencode/service.json")" == 600 ]] \
      || fail "The service configuration must have mode 600"
    grep -qx 'service status' "$OPENCODE_TEST_LOG" \
      || fail "A changed service configuration must check whether the service is running"
    if grep -qx 'service restart' "$OPENCODE_TEST_LOG"; then
      fail "A stopped service must not be started"
    fi
  '';
}

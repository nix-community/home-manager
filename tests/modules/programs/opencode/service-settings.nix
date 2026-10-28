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

  expectedInitial = builtins.toFile "opencode-service-initial.json" (
    builtins.toJSON {
      cors = [ "https://example.com" ];
      disabled = false;
      env = {
        DECLARED = "yes";
        EMPTY = "";
        FROM_FILE = "file";
        QUOTED = "quoted value";
        SHARED = "declared";
        SINGLE = "single value";
      };
      hostname = "127.0.0.1";
      password = "s3cret";
      port = 4096;
      remote.route = "https://remote.example";
    }
  );

  expectedAfterAppChange = builtins.toFile "opencode-service-after-app-change.json" (
    builtins.toJSON {
      cors = [ "https://example.com" ];
      disabled = false;
      env = {
        DECLARED = "yes";
        EMPTY = "";
        FROM_FILE = "file";
        QUOTED = "quoted value";
        SHARED = "declared";
        SINGLE = "single value";
      };
      hostname = "127.0.0.1";
      password = "s3cret";
      port = 4096;
      remote.route = "https://changed.example";
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
      passwordFile = "/@TMPDIR@/secrets/password";
      environmentFile = "/@TMPDIR@/secrets/environment";
      settings = {
        hostname = "127.0.0.1";
        port = 4096;
        cors = [ "https://example.com" ];
        env = {
          DECLARED = "yes";
          SHARED = "declared";
        };
      };
    };
  };

  nmt.script = ''
    export HOME=$TMPDIR/hm-user
    export XDG_CONFIG_HOME=$HOME/.config
    export OPENCODE_TEST_LOG=$TMPDIR/opencode.log
    export OPENCODE_TEST_STATUS=$TMPDIR/opencode.status

    mkdir -p "$HOME/.config/opencode" "$TMPDIR/secrets"
    printf 's3cret\n' > "$TMPDIR/secrets/password"
    cat > "$TMPDIR/secrets/environment" <<'EOF'
    # Comments and blank lines are ignored.

    FROM_FILE=file
    QUOTED="quoted value"
    SINGLE='single value'
    SHARED=file
    EMPTY=
    EOF

    cat > "$HOME/.config/opencode/service.json" <<'EOF'
    {
      "password": "app-generated",
      "remote": {
        "route": "https://remote.example"
      },
      "hostname": "0.0.0.0",
      "port": 9999,
      "cors": ["app-owned"],
      "env": {
        "APP_ONLY": "yes"
      },
      "disabled": false
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
    assertJsonEqual "$HOME/.config/opencode/service.json" ${expectedInitial}
    [[ "$(stat -c '%a' "$HOME/.config/opencode/service.json")" == 600 ]] \
      || fail "The service configuration must have mode 600"
    grep -qx 'service status' "$OPENCODE_TEST_LOG" \
      || fail "A running service must be checked before restarting"
    grep -qx 'service restart' "$OPENCODE_TEST_LOG" \
      || fail "A changed service configuration must restart the service"

    # A second activation is a no-op for a running service.
    : > "$OPENCODE_TEST_LOG"
    ( source $TMPDIR/opencode-service-activate )
    assertJsonEqual "$HOME/.config/opencode/service.json" ${expectedInitial}
    if grep -qx 'service status' "$OPENCODE_TEST_LOG"; then
      fail "An unchanged service configuration must not query the service"
    fi
    if grep -qx 'service restart' "$OPENCODE_TEST_LOG"; then
      fail "An unchanged service configuration must not restart the service"
    fi

    # Declared values are reasserted, while app-owned values survive.
    ${jq} '.port = 9999 | .remote.route = "https://changed.example" | .env = {"APP_ONLY": "yes"}' \
      "$HOME/.config/opencode/service.json" > "$TMPDIR/app-written.json"
    mv "$TMPDIR/app-written.json" "$HOME/.config/opencode/service.json"
    chmod 644 "$HOME/.config/opencode/service.json"
    : > "$OPENCODE_TEST_LOG"
    ( source $TMPDIR/opencode-service-activate )
    assertJsonEqual "$HOME/.config/opencode/service.json" ${expectedAfterAppChange}
    [[ "$(stat -c '%a' "$HOME/.config/opencode/service.json")" == 600 ]] \
      || fail "The service configuration must be private after activation"
    grep -qx 'service restart' "$OPENCODE_TEST_LOG" \
      || fail "An app-owned change must restart the service"

    # A stopped service is never started.
    printf 'stopped\n' > "$OPENCODE_TEST_STATUS"
    ${jq} '.port = 9999' "$HOME/.config/opencode/service.json" > "$TMPDIR/app-written.json"
    mv "$TMPDIR/app-written.json" "$HOME/.config/opencode/service.json"
    : > "$OPENCODE_TEST_LOG"
    ( source $TMPDIR/opencode-service-activate )
    grep -qx 'service status' "$OPENCODE_TEST_LOG" \
      || fail "A stopped service must be checked before a restart"
    if grep -qx 'service restart' "$OPENCODE_TEST_LOG"; then
      fail "A stopped service must not be started"
    fi
    assertJsonEqual "$HOME/.config/opencode/service.json" ${expectedAfterAppChange}

    # A dry run does not change the file or its permissions.
    chmod 644 "$HOME/.config/opencode/service.json"
    cat "$HOME/.config/opencode/service.json" > "$TMPDIR/dry-run-before.json"
    : > "$OPENCODE_TEST_LOG"
    ( export DRY_RUN=1; source $TMPDIR/opencode-service-activate ) > /dev/null
    cmp -s "$TMPDIR/dry-run-before.json" "$HOME/.config/opencode/service.json" \
      || fail "A dry run must not change the service configuration"
    [[ "$(stat -c '%a' "$HOME/.config/opencode/service.json")" == 644 ]] \
      || fail "A dry run must not change the service configuration mode"
    if [[ -s "$OPENCODE_TEST_LOG" ]]; then
      fail "A dry run must not query or restart the service"
    fi
  '';
}

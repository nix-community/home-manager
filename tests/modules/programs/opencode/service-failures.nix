{
  config,
  lib,
  pkgs,
  ...
}:
let
  testOpencode = import ./service-test-opencode.nix { inherit pkgs; };

  activationScript = pkgs.writeScript "opencode-service-activation" ''
    set -eu
    ${config.home.activation.opencodeServiceSettings.data}
  '';

  original = builtins.toFile "opencode-service-original.json" ''
    {
      "password": "original",
      "remote": {
        "route": "https://remote.example"
      },
      "port": 9999
    }
  '';
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
    };
  };

  nmt.script = ''
    export HOME=$TMPDIR/hm-user
    export XDG_CONFIG_HOME=$HOME/.config
    export OPENCODE_TEST_LOG=$TMPDIR/opencode.log
    export OPENCODE_TEST_STATUS=$TMPDIR/opencode.status

    fixtures=$TMPDIR/opencode-failure-fixtures
    mkdir -p "$HOME/.config/opencode" "$TMPDIR/secrets" "$fixtures"
    cat ${original} > "$HOME/.config/opencode/service.json"
    cat ${original} > "$fixtures/original.json"
    chmod 644 "$HOME/.config/opencode/service.json"

    printf 's3cret\n' > "$TMPDIR/secrets/password"
    printf 'GOOD=value\n' > "$TMPDIR/secrets/environment"

    substitute ${activationScript} $TMPDIR/opencode-service-activate --subst-var TMPDIR
    chmod +x $TMPDIR/opencode-service-activate

    # Run activation in a separate shell so `set -e` is not disabled by the
    # surrounding condition.
    cat > $TMPDIR/activate-wrapper <<'EOF'
    set -eu
    function run() { "$@"; }
    function verboseEcho() { printf 'VERBOSE: %s\n' "$*"; }
    function errorEcho() { printf 'ERROR: %s\n' "$*" >&2; }
    source "$TMPDIR/opencode-service-activate"
    EOF
    chmod +x $TMPDIR/activate-wrapper

    function assertUntouched() {
      cmp -s "$fixtures/original.json" "$HOME/.config/opencode/service.json" \
        || fail "A failed activation must not change the service configuration"
      [[ "$(stat -c '%a' "$HOME/.config/opencode/service.json")" == 644 ]] \
        || fail "A failed activation must not change the service configuration mode"
    }
    function assertActivationFails() {
      : > "$OPENCODE_TEST_LOG"
      if "$BASH" $TMPDIR/activate-wrapper 2> "$fixtures/error"; then
        fail "Activation should have failed"
      fi
      assertUntouched
      [[ ! -s "$OPENCODE_TEST_LOG" ]] \
        || fail "A failed activation must not query or restart the service"
    }

    # A missing password file is an error.
    rm "$TMPDIR/secrets/password"
    assertActivationFails
    grep -q 'programs.opencode.service.passwordFile is not readable' "$fixtures/error" \
      || fail "The missing password file error was not reported"

    # An empty password file is an error.
    : > "$TMPDIR/secrets/password"
    assertActivationFails
    grep -q 'programs.opencode.service.passwordFile is empty' "$fixtures/error" \
      || fail "The empty password file error was not reported"

    # A missing environment file is an error.
    printf 's3cret\n' > "$TMPDIR/secrets/password"
    rm "$TMPDIR/secrets/environment"
    assertActivationFails
    grep -q 'programs.opencode.service.environmentFile is not readable' "$fixtures/error" \
      || fail "The missing environment file error was not reported"

    # An invalid environment file is an error with a line number.
    printf '# comment\nGOOD=value\nBAD LINE\n' > "$TMPDIR/secrets/environment"
    assertActivationFails
    grep -q 'invalid environment file line 3: BAD LINE' "$fixtures/error" \
      || fail "The invalid environment file error was not reported"

    # An unparsable existing configuration is not replaced.
    printf 's3cret\n' > "$TMPDIR/secrets/password"
    printf 'GOOD=value\n' > "$TMPDIR/secrets/environment"
    printf '{not json}\n' > "$HOME/.config/opencode/service.json"
    cat "$HOME/.config/opencode/service.json" > "$fixtures/original.json"
    assertActivationFails
    grep -q 'Could not parse OpenCode service configuration' "$fixtures/error" \
      || fail "The unparsable service configuration error was not reported"

    # A non-object existing configuration is not replaced.
    printf '[]\n' > "$HOME/.config/opencode/service.json"
    cat "$HOME/.config/opencode/service.json" > "$fixtures/original.json"
    assertActivationFails
    grep -q 'must be a JSON object' "$fixtures/error" \
      || fail "The non-object service configuration error was not reported"
  '';
}

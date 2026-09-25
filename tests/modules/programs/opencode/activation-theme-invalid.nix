{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./stubs.nix ];

  programs.opencode = {
    enable = true;
    themes = {
      dark = { };
      light = { };
    };
    validation = {
      enable = true;
      extraArgs = [
        "--output-format"
        "json"
      ];
    };
  };

  nmt.script =
    let
      activationScript = pkgs.writeScript "activation" config.home.activation.validateOpenCodeConfigs.data;
    in
    ''
      assertFileExists "${config.programs.opencode.package.passthru.jsonschema.theme}"

      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate

      if stderr=$($TMPDIR/activate 2>&1 >/dev/null); then
        echo "Expected command to fail"
        exit 1
      fi

      ${lib.getExe pkgs.jq} -e '
        .status == "fail"
        and any(.errors[]; .path == "$" and (.message | contains("required property")))
      ' <<<"$stderr" > /dev/null || {
        printf 'Unexpected stderr:\n%s\n' "$stderr"
        exit 1
      }
    '';
}

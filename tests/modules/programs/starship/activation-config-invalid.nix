{
  config,
  pkgs,
  ...
}:

{
  imports = [ ./stubs.nix ];

  programs.starship = {
    enable = true;
    settings.add_newline = "invalid";
    validation.enable = true;
  };

  nmt.script =
    let
      activationScript = pkgs.writeScript "activation" config.home.activation.validateStarshipConfig.data;
    in
    ''
      assertFileExists "${config.programs.starship.package.passthru.jsonschema.config}"

      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate

      if output=$($TMPDIR/activate 2>&1 >/dev/null); then
        fail "expected activation to fail but it succeeded"
      fi

      if [[ "$output" != *"'invalid' is not of type 'boolean'"* ]]; then
        fail "expected error message to contain \"'invalid' is not of type 'boolean'\", got: $output"
      fi
    '';
}

{
  config,
  pkgs,
  ...
}:

{
  imports = [ ./stubs.nix ];

  programs.opencode = {
    enable = true;
    tui.theme = "solarized";
    validation.enable = true;
  };

  nmt.script =
    let
      activationScript = pkgs.writeScript "activation" config.home.activation.validateOpenCodeConfigs.data;
    in
    ''
      assertFileExists "${config.programs.opencode.package.passthru.jsonschema.tui}"

      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      $TMPDIR/activate
    '';
}

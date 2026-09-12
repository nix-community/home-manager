{
  config,
  pkgs,
  ...
}:

{
  imports = [ ./stubs.nix ];

  programs.opencode = {
    enable = true;
    settings.autoupdate = false;
    validation.enable = true;
  };

  nmt.script =
    let
      activationScript = pkgs.writeScript "activation" config.home.activation.validateOpenCodeConfigs.data;
    in
    ''
      assertFileExists "${config.programs.opencode.package.passthru.jsonschema.config}"

      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      $TMPDIR/activate
    '';
}

{
  config,
  pkgs,
  ...
}:

{
  imports = [ ./stubs.nix ];

  programs.starship = {
    enable = true;
    settings.add_newline = false;
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
      $TMPDIR/activate
    '';
}

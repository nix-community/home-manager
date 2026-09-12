{ config, pkgs, ... }:

{
  home.file.test-file.text = "test content";

  nmt.script =
    let
      activationScript = pkgs.writeScript "activation" config.home.activation.validateFiles.data;
    in
    ''
      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      assertFileIsExecutable "$TMPDIR/activate"

      $TMPDIR/activate
    '';
}

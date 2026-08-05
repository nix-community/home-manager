{ config, pkgs, ... }:

{
  home.file = {
    test-file-1 = {
      text = "test content 1";
      validate = {
        enabled = true;
        validator = { source }: "echo 'validated ${source}'";
      };
    };
    test-file-2 = {
      text = "test content 2";
      validate = {
        enabled = true;
        validator = { source }: "echo 'validated ${source}'";
      };
    };
  };

  nmt.script =
    let
      activationScript = pkgs.writeScript "activation" config.home.activation.validateFiles.data;
    in
    ''
      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      assertFileIsExecutable "$TMPDIR/activate"

      $TMPDIR/activate &> $TMPDIR/output
      assertFileExists "$TMPDIR/output"
      assertFileRegex "$TMPDIR/output" "validated /nix/store/.*-hm_testfile1"
      assertFileRegex "$TMPDIR/output" "validated /nix/store/.*-hm_testfile2"
    '';
}

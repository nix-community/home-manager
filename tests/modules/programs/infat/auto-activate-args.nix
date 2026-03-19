{
  config,
  pkgs,
  ...
}:

let
  activationScript = pkgs.writeText "activation-script" config.home.activation.infat.data;
in
{
  programs.infat = {
    enable = true;
    autoActivate.extraArgs = {
      quiet = true;
    };
    settings = {
      extensions = {
        md = "TextEdit";
      };
    };
  };

  test.stubs.infat = { };

  nmt.script = ''
    assertFileRegex "${activationScript}" '\-\-config'
    assertFileRegex "${activationScript}" '\-\-quiet'
    assertFileNotRegex "${activationScript}" '\-\-robust'
  '';
}

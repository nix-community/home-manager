{ config, pkgs, ... }:

{
  programs.infat = {
    enable = true;
    settings = {
      extensions = {
        md = "TextEdit";
      };
      schemes = {
        web = "Safari";
      };
      types = {
        plain-text = "VSCode";
      };
    };
  };

  test.stubs.infat = { };

  nmt.script =
    let
      expectedConfigPath = "home-files/.config/infat/config.toml";
      expectedConfigContent = pkgs.writeText "infat.config.expected" ''
        [extensions]
        md = "TextEdit"

        [schemes]
        web = "Safari"

        [types]
        plain-text = "VSCode"
      '';
    in
    # infat reads the linked config, so it must run after linkGeneration.
    assert config.home.activation.infat.after == [ "linkGeneration" ];
    ''
      assertFileExists "${expectedConfigPath}"
      assertFileContent "${expectedConfigPath}" "${expectedConfigContent}"
      assertFileContains activate ' --robust'
    '';
}

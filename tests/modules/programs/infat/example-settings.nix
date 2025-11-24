{ pkgs, ... }:

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
    ''
      assertFileExists "${expectedConfigPath}"
      assertFileContent "${expectedConfigPath}" "${expectedConfigContent}"
    '';
}

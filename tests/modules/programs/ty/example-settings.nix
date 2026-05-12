{ pkgs, ... }:

{
  programs.ty = {
    enable = true;
    settings = {
      rules.index-out-of-bounds = "ignore";
    };
  };

  test.stubs.ty = { };

  nmt.script =
    let
      expectedConfigPath = "home-files/.config/ty/ty.toml";
      expectedConfigContent = pkgs.writeText "ty.config-custom.expected" ''
        [rules]
        index-out-of-bounds = "ignore"
      '';
    in
    ''
      assertFileExists "${expectedConfigPath}"
      assertFileContent "${expectedConfigPath}" "${expectedConfigContent}"
    '';
}

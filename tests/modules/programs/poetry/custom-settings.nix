{ pkgs, ... }:

{
  programs.poetry = {
    enable = true;
    settings = {
      virtualenvs.create = true;
      virtualenvs.in-project = true;
    };
  };

  nmt.script =
    let
      expectedConfigPath = "home-files/.config/pypoetry/config.toml";
      expectedConfigContent = pkgs.writeText "poetry.config-custom.expected" ''
        [virtualenvs]
        create = true
        in-project = true
      '';
    in
    ''
      assertFileExists "${expectedConfigPath}"
      assertFileContent "${expectedConfigPath}" "${expectedConfigContent}"
    '';
}

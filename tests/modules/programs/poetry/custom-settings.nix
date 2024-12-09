{ pkgs, ... }:

{
  programs.poetry = {
    enable = true;
    settings = {
      virtualenvs.create = true;
      virtualenvs.in-project = true;
    };
  };

  test.stubs.poetry = { };

  nmt.script = let
    expectedConfDir =
      if pkgs.stdenv.isDarwin then "Library/Application Support" else ".config";
    expectedConfigPath = "home-files/${expectedConfDir}/pypoetry/config.toml";
    expectedConfigContent = pkgs.writeText "poetry.config-custom.expected" ''
      [virtualenvs]
      create = true
      in-project = true
    '';
  in ''
    assertFileExists "${expectedConfigPath}"
    assertFileContent "${expectedConfigPath}" "${expectedConfigContent}"
  '';
}

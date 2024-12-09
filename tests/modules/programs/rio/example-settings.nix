{ config, pkgs, ... }:

let
  expected = pkgs.writeText "rio-expected.toml" ''
    cursor = "_"
    padding-x = 0
    performance = "Low"
  '';
in {
  programs.rio = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      cursor = "_";
      performance = "Low";
      padding-x = 0;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/rio/config.toml
    assertFileContent home-files/.config/rio/config.toml '${expected}'
  '';
}

{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  path = if isDarwin then
    "Library/Application Support/rio/config.toml"
  else
    ".config/rio/config.toml";

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
    assertFileExists home-files/"${path}"
    assertFileContent home-files/"${path}" '${expected}'
  '';
}

{ config, pkgs, ... }:

let
  configFile = if pkgs.stdenv.isDarwin then
    "home-files/Library/Application Support/jj/config.toml"
  else
    "home-files/.config/jj/config.toml";

in {
  programs.jujutsu = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    settings = {
      user = {
        name = "John Doe";
        email = "jdoe@example.org";
      };
    };
  };

  nmt.script = ''
    assertFileExists "${configFile}"
    assertFileContent \
      "${configFile}" \
      ${
        builtins.toFile "expected.toml" ''
          [user]
          email = "jdoe@example.org"
          name = "John Doe"
        ''
      }
  '';
}

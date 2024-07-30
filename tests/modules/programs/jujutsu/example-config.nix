{ pkgs, config, ... }:

let
  configDir =
    if pkgs.stdenv.isDarwin then "Library/Application Support" else ".config";
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
    assertFileExists 'home-files/${configDir}/jj/config.toml'
    assertFileContent 'home-files/${configDir}/jj/config.toml' \
      ${
        builtins.toFile "expected.toml" ''
          [user]
          email = "jdoe@example.org"
          name = "John Doe"
        ''
      }
  '';
}

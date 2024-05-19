{ pkgs, config, ... }:

let
  expectedConfDir =
    if pkgs.stdenv.isDarwin then "Library/Application Support" else ".config";
  expectedConfigPath = "home-files/${expectedConfDir}/jj/config.toml";
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
    assertFileExists ${expectedConfigPath}
    assertFileContent ${expectedConfigPath} \
      ${
        builtins.toFile "expected.toml" ''
          [user]
          email = "jdoe@example.org"
          name = "John Doe"
        ''
      }
  '';
}

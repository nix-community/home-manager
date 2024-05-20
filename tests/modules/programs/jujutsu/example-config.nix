{ config, ... }:

{
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
    assertFileExists home-files/.config/jj/config.toml
    assertFileContent \
      home-files/.config/jj/config.toml \
      ${
        builtins.toFile "expected.toml" ''
          [user]
          email = "jdoe@example.org"
          name = "John Doe"
        ''
      }
  '';
}

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
    assertFileExists home-files/.jjconfig.toml
    assertFileContent \
      home-files/.jjconfig.toml \
      ${
        builtins.toFile "expected.toml" ''
          [user]
          email = "jdoe@example.org"
          name = "John Doe"
        ''
      }
  '';
}

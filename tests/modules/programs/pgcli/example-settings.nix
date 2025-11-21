{ config, ... }:

let
  expected = builtins.toFile "config" ''
    [main]
    vi=true
  '';
in
{
  programs.pgcli = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      main.vi = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/pgcli/config
    assertFileContent home-files/.config/pgcli/config '${expected}'
  '';
}

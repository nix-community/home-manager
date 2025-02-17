{ config, ... }:

{
  programs.vifm = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    extraConfig = ''
      mark h ~/
    '';
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/vifm/vifmrc \
      ${
        builtins.toFile "vifm-expected.conf" ''
          mark h ~/
        ''
      }
  '';
}

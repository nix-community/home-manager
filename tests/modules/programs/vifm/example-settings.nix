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
      ${./example-settings-expected.vifmrc}
  '';
}

{ config, lib, ... }:

with lib;

{
  config = {
    programs.looking-glass-client = {
      enable = true;
      package = config.lib.test.mkStubPackage { };

      settings = {
        app = {
          allowDMA = true;
          shmFile = "/dev/kvmfr0";
        };

        win = {
          fullScreen = true;
          showFPS = false;
          jitRender = true;
        };

        spice = {
          enable = true;
          audio = true;
        };

        input = {
          rawMouse = true;
          escapeKey = 62;
        };
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/looking-glass/client.ini \
        ${./example-config.ini}
    '';
  };
}

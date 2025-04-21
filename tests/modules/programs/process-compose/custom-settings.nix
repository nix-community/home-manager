{ config, pkgs, ... }:
{
  config = {
    programs.process-compose = {
      package = config.lib.test.mkStubPackage { name = "process-compose"; };
      enable = true;
      settings = {
        theme = "Custom Style";
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/process-compose/settings.yaml
      assertFileContent home-files/.config/process-compose/settings.yaml ${pkgs.writeText "process-compose.config-custom.expected" ''
        theme: Custom Style
      ''}
    '';
  };
}

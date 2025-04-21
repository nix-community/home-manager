{ config, pkgs, ... }:
{
  config = {
    programs.process-compose = {
      package = config.lib.test.mkStubPackage { name = "process-compose"; };
      enable = true;
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/process-compose/settings.yaml
    '';
  };
}

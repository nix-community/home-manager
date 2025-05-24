{ config, pkgs, ... }:
{
  config = {
    programs.process-compose = {
      package = config.lib.test.mkStubPackage { name = "process-compose"; };
      enable = true;
    };

    nmt.script =
      let
        configDir =
          if pkgs.stdenv.isDarwin then
            "home-files/Library/Application Support/process-compose"
          else
            "home-files/.config/process-compose";
      in
      ''
        assertPathNotExists "${configDir}/settings.yaml"
      '';
  };
}

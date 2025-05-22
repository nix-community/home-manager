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

    nmt.script =
      let
        configDir =
          if pkgs.stdenv.isDarwin then
            "home-files/Library/Application Support/process-compose"
          else
            "home-files/.config/process-compose";
      in
      ''
        assertFileExists "${configDir}/settings.yaml"
        assertFileContent "${configDir}/settings.yaml" ${pkgs.writeText "process-compose.config-custom.expected" ''
          theme: Custom Style
        ''}
      '';
  };
}

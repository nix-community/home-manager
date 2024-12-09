{ config, pkgs, ... }: {
  config = {
    programs.tealdeer = {
      package = config.lib.test.mkStubPackage { name = "tldr"; };
      enable = true;
      settings = {
        updates = {
          auto_update = true;
          auto_update_interval_hours = 72;
        };
        display = { use_pager = false; };
      };
    };

    nmt.script = let
      expectedConfDir = if pkgs.stdenv.isDarwin then
        "Library/Application Support"
      else
        ".config";
      expectedConfigPath = "home-files/${expectedConfDir}/tealdeer/config.toml";
    in ''
      assertFileExists "${expectedConfigPath}"
      assertFileContent "${expectedConfigPath}" ${
        pkgs.writeText "tealdeer.config-custom.expected" ''
          [display]
          use_pager = false

          [updates]
          auto_update = true
          auto_update_interval_hours = 72
        ''
      }
    '';
  };
}

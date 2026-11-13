{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs.tealdeer = {
      package = config.lib.test.mkStubPackage {
        name = "tldr";
        version = "1.8.0";
      };
      enable = true;
      settings = {
        updates = {
          auto_update = true;
          auto_update_interval_hours = 72;
        };
      };
    };

    nmt.script =
      let
        expectedConfDir =
          if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else ".config";
        expectedConfigPath = "home-files/${expectedConfDir}/tealdeer/config.toml";
      in
      ''
        assertFileExists "${expectedConfigPath}"
        assertFileContent "${expectedConfigPath}" ${pkgs.writeText "tealdeer.config-custom.expected" ''
          [updates]
          auto_update = true
          auto_update_interval_hours = 72
        ''}
      '';
  };
}

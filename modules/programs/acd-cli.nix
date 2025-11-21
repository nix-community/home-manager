{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.acd-cli;
  iniFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.acd-cli = {
    enable = mkEnableOption "acd-cli";
    package = mkPackageOption pkgs "acd-cli" { nullable = true; };
    cliSettings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = {
        download = {
          keep_corrupt = false;
          keep_incomplete = true;
        };

        upload = {
          timeout_wait = 10;
        };
      };
      description = ''
        CLI configuration settings for acd-cli. All the available options can be found here:
        <https://acd-cli.readthedocs.io/en/latest/configuration.html#acd-cli-ini>.
      '';
    };

    clientSettings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = {
        endpoints = {
          filename = "endpoint_data";
          validity_duration = 259200;
        };

        transfer = {
          fs_chunk_size = 131072;
          dl_chunk_size = 524288000;
          chunk_retries = 1;
          connection_timeout = 30;
          idle_timeout = 60;
        };
      };
      description = ''
        Client configuration settings for acd-cli. All the available options can be found here:
        <https://acd-cli.readthedocs.io/en/latest/configuration.html#acd-client-ini>.
      '';
    };

    cacheSettings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = {
        sqlite = {
          filename = "nodes.db";
          busy_timeout = 30000;
          journal_mode = "wal";
        };

        blacklist = {
          folders = [ ];
        };
      };
      description = ''
        Cache configuration settings for acd-cli. All the available options can be found here:
        <https://acd-cli.readthedocs.io/en/latest/configuration.html#cache-ini>.
      '';
    };

    fuseSettings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = {
        fs.block_size = 512;
        read.open_chunk_limit = 10;
        write = {
          buffer_size = 32;
          timeout = 30;
        };
      };
      description = ''
        FUSE configuration settings for acd-cli. All the available options can be found here:
        <https://acd-cli.readthedocs.io/en/latest/configuration.html#fuse-ini>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile = {
      "acd_cli/acd_cli.ini" = mkIf (cfg.cliSettings != { }) {
        source = iniFormat.generate "acd_cli.ini" cfg.cliSettings;
      };
      "acd_cli/acd_client.ini" = mkIf (cfg.clientSettings != { }) {
        source = iniFormat.generate "acd_client.ini" cfg.clientSettings;
      };
      "acd_cli/cache.ini" = mkIf (cfg.cacheSettings != { }) {
        source = iniFormat.generate "acd_cli_cache.ini" cfg.cacheSettings;
      };
      "acd_cli/fuse.ini" = mkIf (cfg.fuseSettings != { }) {
        source = iniFormat.generate "acd_cli_fuse.ini" cfg.fuseSettings;
      };
    };
  };
}

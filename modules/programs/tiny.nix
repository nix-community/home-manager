{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.tiny;
  format = pkgs.formats.yaml { };
  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support/tiny"
  else
    "${config.xdg.configHome}/tiny";
in {
  meta.maintainers = [ hm.maintainers.kmaasrud ];

  options = {
    programs.tiny = {
      enable = mkEnableOption "tiny, a TUI IRC client written in Rust";

      package = mkOption {
        type = types.package;
        default = pkgs.tiny;
        defaultText = literalExpression "pkgs.tiny";
        description = "The {command}`tiny` package to install.";
      };

      settings = mkOption {
        type = format.type;
        default = { };
        defaultText = literalExpression "{ }";
        example = literalExpression ''
          {
            servers = [
              {
                addr = "irc.libera.chat";
                port = 6697;
                tls = true;
                realname = "John Doe";
                nicks = [ "tinyuser" ];
              }
            ];
            defaults = {
              nicks = [ "tinyuser" ];
              realname = "John Doe";
              join = [];
              tls = true;
            };
          };
        '';
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/tiny/config.yml`. See
          <https://github.com/osa1/tiny/blob/master/crates/tiny/config.yml>
          for the default configuration.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."${configDir}/config.yml" = mkIf (cfg.settings != { }) {
      source = format.generate "tiny-config" cfg.settings;
    };
  };
}

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.miniplayer;

  iniFormat = pkgs.formats.ini { };
in {
  meta.maintainers = [ maintainers.h7x4 ];

  options.programs.miniplayer = {
    enable = mkEnableOption
      "Miniplayer - A curses-based MPD client with album art support";

    package = mkPackageOption pkgs "miniplayer" { };

    imageMethod = mkOption {
      type = types.enum [ "ueberzug" "pixcat" ];
      default = "ueberzug";
      description = "Library used to display album art";
    };

    mpd = let mpdCfg = config.services.mpd;
    in {
      host = mkOption {
        type = types.str;
        default = if pkgs.stdenv.hostPlatform.isLinux && mpdCfg.enable then
          mpdCfg.network.listenAddress
        else
          "127.0.0.1";
        defaultText = literalExpression ''
          if pkgs.stdenv.hostPlatform.isLinux && config.services.mpd.enable then
            config.services.mpd.network.listenAddress
          else
            "127.0.0.1"
        '';
        description = "The address that the mpd daemon listens to.";
      };
      port = mkOption {
        type = types.port;
        default = if pkgs.stdenv.hostPlatform.isLinux && mpdCfg.enable then
          mpdCfg.network.port
        else
          6600;
        defaultText = literalExpression ''
          if pkgs.stdenv.hostPlatform.isLinux && config.services.mpd.enable then
            config.services.mpd.network.port
          else
            6600
        '';
        description = "The TCP port of the mpd daemon.";
      };
      pass = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The password of the mpd daemon, if there is any.";
      };
    };

    settings = mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Attribute set from name of a setting to its value. For available options
        see
        <link xlink:href="https://github.com/GuardKenzie/miniplayer/blob/main/config.example" />
      '';
      example = literalExpression ''
        {
          player = {
            font_width = 11;
            font_height = 24;
            album_art_only = false;
          };
          theme = {
            time_color = "green";
            bar_head = ">";
          };
        }
      '';
    };

    bindings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Override keybindings. For a list of default keybindings and available
        functions, see
        <link xlink:href="https://github.com/GuardKenzie/miniplayer#keybindings" />
      '';
      example = literalExpression ''
        {
          j = "select_down";
          k = "select_up";
          J = "move_up";
          K = "move_down";
          delete = "delete";
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."miniplayer/config" = let
      shouldGenerateConfig = lib.any (attrs: attrs != { })
        (with cfg; [ imageMethod bindings settings bindings ]);
      mergedConfig = cfg.settings // {
        art.image_method = cfg.imageMethod;
        mpd = {
          inherit (cfg.mpd) host port;
        } // optionalAttrs (cfg.mpd.pass != null) { inherit (cfg.mpd) pass; };
        keybindings = cfg.bindings;
      };
    in mkIf shouldGenerateConfig {
      source = iniFormat.generate "miniplayer-config.ini" mergedConfig;
    };
  };
}

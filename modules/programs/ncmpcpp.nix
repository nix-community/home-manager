{ config, lib, pkgs, ... }:

let
  inherit (lib) types mkIf mkEnableOption mkOption;

  cfg = config.programs.ncmpcpp;

  mpdCfg = config.services.mpd;

  renderSettings = settings:
    lib.concatStringsSep "\n" (lib.mapAttrsToList renderSetting settings);

  renderSetting = name: value: "${name}=${renderValue value}";

  renderValue = option:
    {
      int = toString option;
      bool = if option then "yes" else "no";
      string = option;
    }.${builtins.typeOf option};

  renderBindings = bindings:
    lib.concatStringsSep "\n" (map renderBinding bindings);

  renderBinding = { key, command }:
    lib.concatStringsSep "\n  "
    ([ ''def_key "${key}"'' ] ++ maybeWrapList command);

  maybeWrapList = xs: if lib.isList xs then xs else [ xs ];

  valueType = with types; oneOf [ bool int str ];

  bindingType = types.submodule ({ name, config, ... }: {
    options = {
      key = mkOption {
        type = types.str;
        description = "Key to bind.";
        example = "j";
      };

      command = mkOption {
        type = with types; either str (listOf str);
        description = "Command or sequence of commands to be executed.";
        example = "scroll_down";
      };
    };
  });

in {
  meta.maintainers = with lib.maintainers; [ olmokramer ];

  options.programs.ncmpcpp = {
    enable =
      mkEnableOption "ncmpcpp - An ncurses Music Player Daemon (MPD) client";

    package = mkOption {
      type = types.package;
      default = pkgs.ncmpcpp;
      defaultText = "pkgs.ncmpcpp";
      description = "Package providing the <code>ncmpcpp</code> command.";
      example = "pkgs.ncmpcpp.override { ... }";
    };

    mpdMusicDir = mkOption {
      type = types.nullOr types.path;
      default = if mpdCfg.enable then mpdCfg.musicDirectory else null;
      defaultText = lib.literalExample ''
        if config.services.mpd.enable then
          config.services.mpd.musicDirectory
        else
          null
      '';
      description = ''
        Value of the <code>mpd_music_dir</code> setting. The value of
        services.mpd.musicDirectory is used as the default if
        services.mpd.enable is <literal>true</literal>.
      '';
      example = "~/music";
    };

    settings = mkOption {
      type = types.attrsOf valueType;
      default = { };
      description = ''
        Attrset from name of a setting to its value. For available options
        See
        <citerefentry>
          <refentrytitle>ncmpcpp</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>
      '';
      example = lib.literalExample ''
        {
          ncmpcpp_directory = "~/.local/share/ncmpcpp";
        }
      '';
    };

    bindings = mkOption {
      type = types.listOf bindingType;
      default = [ ];
      description = "List of keybindings.";
      example = lib.literalExample ''
        [
          { key = "j"; command = "scroll_down"; }
          { key = "k"; command = "scroll_up"; }
          { key = "J"; command = [ "select_item" "scroll_down" ]; }
          { key = "K"; command = [ "select_item" "scroll_up" ]; }
        ]
      '';
    };
  };

  config = mkIf cfg.enable {
    warnings = mkIf (cfg.settings ? mpd_music_dir && cfg.mpdMusicDir != null) [
      ("programs.ncmpcpp.settings.mpd_music_dir will be overridden by"
        + " programs.ncmpcpp.mpdMusicDir.")
    ];

    home.packages = [ cfg.package ];

    xdg.configFile = {
      "ncmpcpp/config" = let
        settings = cfg.settings // lib.optionalAttrs (cfg.mpdMusicDir != null) {
          mpd_music_dir = toString cfg.mpdMusicDir;
        };
      in mkIf (lib.length (lib.attrValues settings) > 0) {
        text = renderSettings settings + "\n";
      };

      "ncmpcpp/bindings" = mkIf (lib.length cfg.bindings > 0) {
        text = renderBindings cfg.bindings + "\n";
      };
    };
  };
}

{ config, lib, pkgs, ... }:

let
  inherit (lib) types mkIf mkEnableOption mkOption;

  cfg = config.programs.ncmpcpp;

  mpdCfg = config.services.mpd;

  mpdMusicDir = if cfg.mpdMusicDir == null then
    mpdCfg.musicDirectory
  else
    toString cfg.mpdMusicDir;

  renderSettings = settings:
    lib.concatStringsSep "\n" (lib.mapAttrsToList renderSetting settings);

  renderSetting = name: value: "${name}=${renderValue value}";

  renderValue = option:
    rec {
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

  valueType = types.oneOf [ types.bool types.int types.str ];

  bindingType = types.submodule ({ name, config, ... }: {
    options = {
      key = mkOption {
        type = types.str;
        description = "Key to bind.";
        example = "j";
      };

      command = mkOption {
        type = types.either types.str (types.listOf types.str);
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
      default = null;
      description = ''
        Value of the <code>mpd_music_dir</code> option. The value of
        services.mpd.musicDirectory is used if set to <literal>null</literal>.
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
    assertions = [
      {
        assertion = cfg.mpdMusicDir != null || mpdCfg.enable;
        message = "Either set programs.ncmpcpp.mpdMusicDir or enable"
          + " Home manager's MPD service with services.mpd.enable to"
          + " use services.mpd.musicDirectory.";
      }
      {
        assertion = !(cfg.settings ? mpd_music_dir);
        message = "ncmpcpp's mpd_music_dir setting should be configured"
          + " through the programs.ncmpcpp.mpdMusicDir option.";
      }
    ];

    home.packages = [ cfg.package ];

    xdg.configFile = {
      "ncmpcpp/config".text = ''
        mpd_music_dir=${mpdMusicDir}
        ${renderSettings cfg.settings}
      '';

      "ncmpcpp/bindings" = lib.mkIf (lib.length cfg.bindings > 0) {
        text = ''
          ${renderBindings cfg.bindings}
        '';
      };
    };
  };
}

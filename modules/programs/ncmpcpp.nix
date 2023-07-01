{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.ncmpcpp;

  renderSettings = settings:
    concatStringsSep "\n" (mapAttrsToList renderSetting settings);

  renderSetting = name: value: "${name}=${renderValue value}";

  renderValue = option:
    {
      int = toString option;
      bool = lib.hm.booleans.yesNo option;
      string = option;
    }.${builtins.typeOf option};

  renderBindings = bindings: concatStringsSep "\n" (map renderBinding bindings);

  renderBinding = { key, command }:
    concatStringsSep "\n  " ([ ''def_key "${key}"'' ] ++ maybeWrapList command);

  maybeWrapList = xs: if isList xs then xs else [ xs ];

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
  meta.maintainers = [ hm.maintainers.olmokramer ];

  options.programs.ncmpcpp = {
    enable =
      mkEnableOption "ncmpcpp - an ncurses Music Player Daemon (MPD) client";

    package = mkOption {
      type = types.package;
      default = pkgs.ncmpcpp;
      defaultText = literalExpression "pkgs.ncmpcpp";
      description = ''
        Package providing the `ncmpcpp` command.
      '';
      example =
        literalExpression "pkgs.ncmpcpp.override { visualizerSupport = true; }";
    };

    mpdMusicDir = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = let mpdCfg = config.services.mpd;
      in if pkgs.stdenv.hostPlatform.isLinux && mpdCfg.enable then
        mpdCfg.musicDirectory
      else
        null;
      defaultText = literalExpression ''
        if pkgs.stdenv.hostPlatform.isLinux && config.services.mpd.enable then
          config.services.mpd.musicDirectory
        else
          null
      '';
      description = ''
        Value of the `mpd_music_dir` setting. On Linux platforms the
        value of {var}`services.mpd.musicDirectory` is used as the
        default if {var}`services.mpd.enable` is
        `true`.
      '';
      example = "~/music";
    };

    settings = mkOption {
      type = types.attrsOf valueType;
      default = { };
      description = ''
        Attribute set from name of a setting to its value. For available options
        see
        {manpage}`ncmpcpp(1)`.
      '';
      example = { ncmpcpp_directory = "~/.local/share/ncmpcpp"; };
    };

    bindings = mkOption {
      type = types.listOf bindingType;
      default = [ ];
      description = "List of keybindings.";
      example = literalExpression ''
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
        settings = cfg.settings // optionalAttrs (cfg.mpdMusicDir != null) {
          mpd_music_dir = cfg.mpdMusicDir;
        };
      in mkIf (settings != { }) { text = renderSettings settings + "\n"; };

      "ncmpcpp/bindings" = mkIf (cfg.bindings != [ ]) {
        text = renderBindings cfg.bindings + "\n";
      };
    };
  };
}

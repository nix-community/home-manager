{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.yt-dlp;

  renderSettings = mapAttrsToList (name: value:
    if isBool value then
      if value then "--${name}" else "--no-${name}"
    else
      "--${name} ${toString value}");

in {
  meta.maintainers = [ ];

  options.programs.yt-dlp = {
    enable = mkEnableOption "yt-dlp";

    package = mkOption {
      type = types.package;
      default = pkgs.yt-dlp;
      defaultText = literalExpression "pkgs.yt-dlp";
      description = "Package providing the {command}`yt-dlp` tool.";
    };

    settings = mkOption {
      type = with types; attrsOf (oneOf [ bool int str ]);
      default = { };
      example = literalExpression ''
        {
          embed-thumbnail = true;
          embed-subs = true;
          sub-langs = "all";
          downloader = "aria2c";
          downloader-args = "aria2c:'-c -x8 -s8 -k1M'";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/yt-dlp/config`.

        Options must be specified in their "long form", for
        example, `update = true;` instead of `U = true;`.
        Short options can be specified in the `extraConfig` option.
        See <https://github.com/yt-dlp/yt-dlp#configuration>
        for explanation about possible values.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        --update
        -F
      '';
      description = ''
        Extra configuration to add to
        {file}`$XDG_CONFIG_HOME/yt-dlp/config`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."yt-dlp/config" =
      mkIf (cfg.settings != { } || cfg.extraConfig != "") {
        text = concatStringsSep "\n"
          (remove "" (renderSettings cfg.settings ++ [ cfg.extraConfig ]))
          + "\n";
      };
  };
}

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
  meta.maintainers = [ maintainers.marsam ];

  options.programs.yt-dlp = {
    enable = mkEnableOption "yt-dlp";

    package = mkOption {
      type = types.package;
      default = pkgs.yt-dlp;
      defaultText = literalExpression "pkgs.yt-dlp";
      description = "Package providing the <command>yt-dlp</command> tool.";
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
        <filename>$XDG_CONFIG_HOME/yt-dlp/config</filename>.
        </para><para>
        Options must be specified in their <quote>long form</quote>, for
        example, <code>update = true;</code> instead of <code>U = true;</code>.
        Short options can be specified in the <code>extraConfig</code> option.
        See <link xlink:href="https://github.com/yt-dlp/yt-dlp#configuration"/>
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
        <filename>$XDG_CONFIG_HOME/yt-dlp/config</filename>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."yt-dlp/config" = mkIf (cfg.settings != { }) {
      text = concatStringsSep "\n"
        (remove "" (renderSettings cfg.settings ++ [ cfg.extraConfig ])) + "\n";
    };
  };
}

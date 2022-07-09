{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.yt-dlp;

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

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = literalExpression ''
        --embed-thumbnail
        --embed-subs
        --sub-langs all
        --downloader aria2c
        --downloader-args aria2c:'-c -x8 -s8 -k1M'
      '';
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/yt-dlp/config</filename>. See
        <link xlink:href="https://github.com/yt-dlp/yt-dlp#configuration" />
        for explanation about possible values.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."yt-dlp/config" =
      mkIf (cfg.extraConfig != "") { text = cfg.extraConfig; };
  };
}

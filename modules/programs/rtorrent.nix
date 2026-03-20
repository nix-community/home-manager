{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rtorrent;
in
{
  meta.maintainers = [ ];

  imports = [
    (lib.mkRenamedOptionModule # \
      [ "programs" "rtorrent" "settings" ] # \
      [ "programs" "rtorrent" "extraConfig" ]
    )
  ];

  options.programs.rtorrent = {
    enable = lib.mkEnableOption "rTorrent";

    package = lib.mkPackageOption pkgs "rtorrent" { nullable = true; };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/rtorrent/rtorrent.rc`. See
        <https://github.com/rakshasa/rtorrent/wiki/Config-Guide>
        for explanation about possible values.
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."rtorrent/rtorrent.rc" = lib.mkIf (cfg.extraConfig != "") {
      text = cfg.extraConfig;
    };
  };
}

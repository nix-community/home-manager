{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.screen;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.screen = {
    enable = mkEnableOption "screen";
    package = mkPackageOption pkgs "screen" { nullable = true; };
    screenrc = mkOption {
      type = with types; nullOr (either path lines);
      default = null;
      example = ''
        screen -t rtorrent rtorrent
        screen -t irssi irssi
        screen -t centerim centerim
        screen -t ncmpc ncmpc -c
        screen -t bash4
        screen -t bash5
        screen -t bash6
        screen -t bash7
        screen -t bash8
        screen -t bash9
        altscreen on
        term screen-256color
        bind ',' prev
        bind '.' next
      '';
      description = ''
        Config file for GNU Screen. All the details can be found here:
        <https://www.gnu.org/software/screen/manual/screen.html>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file.".screenrc" = mkIf (cfg.screenrc != null) {
      source = if lib.isPath cfg.screenrc then cfg.screenrc else pkgs.writeText "screenrc" cfg.screenrc;
    };
  };
}

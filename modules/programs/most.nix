{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.most;

in {
  options.programs.most = {
    enable = mkEnableOption "Most, a powerful paging program";
    sessionPager =
      mkEnableOption "use Most as the session pager, e.g. for manpages";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.most ];
    home.sessionVariables = mkIf cfg.sessionPager { PAGER = "most"; };
  };

  meta.maintainers = with maintainers; [ j0hax ];
}

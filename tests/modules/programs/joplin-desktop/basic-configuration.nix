{ config, pkgs, ... }:

{
  config = {
    programs.joplin-desktop = {
      enable = true;
      package = pkgs.joplin-desktop;
      sync = {
        target = "dropbox";
        interval = "10m";
      };
      extraConfig = {
        "richTextBannerDismissed" = true;
        "newNoteFocus" = "title";
      };
    };
  };
}

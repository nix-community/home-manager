{ config, ... }:

{
  config = {
    home.stateVersion = "26.05";

    xdg.userDirs = {
      enable = true;
      extraConfig.XDG_MISC_DIR = "${config.home.homeDirectory}/Misc";
    };

    test.asserts.warnings.expected = [ ];
  };
}

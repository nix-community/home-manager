modulePath:
{ config, lib, ... }:

lib.mkIf config.test.enableBig (
  lib.setAttrByPath modulePath { enable = true; }
  // {
    home.stateVersion = "26.05";

    programs.firefox = {
      enable = true;
      package = null;
    };
  }
)

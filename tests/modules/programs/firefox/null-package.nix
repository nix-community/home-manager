modulePath:
{ config, lib, ... }:

lib.mkIf config.test.enableBig (
  lib.setAttrByPath modulePath { enable = true; }
  // {
    programs.firefox = {
      enable = true;
      package = null;
    };
  }
)

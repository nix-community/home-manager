{ config, lib, ... }:

lib.mkIf config.test.enableBig {
  programs.firefox = {
    enable = true;
    package = null;
  };
  programs.floorp = {
    enable = true;
    package = null;
  };
  programs.librewolf = {
    enable = true;
    package = null;
  };
}

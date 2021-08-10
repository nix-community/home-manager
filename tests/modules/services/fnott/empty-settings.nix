{ config, lib, pkgs, ... }:

{
  config = {
    services.fnott = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-fnott" "";
      settings = { };
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/fnott
    '';
  };
}

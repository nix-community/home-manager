{ config, lib, ... }:

with lib;

{
  config = {
    xresources.properties = { };

    nmt.script = ''
      assertPathNotExists home-files/.Xresources
    '';
  };
}

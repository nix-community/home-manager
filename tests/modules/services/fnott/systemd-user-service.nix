{ config, lib, pkgs, ... }:

{
  config = {
    services.fnott = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-foot" "" // { outPath = "@fnott@"; };
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/fnott/fnott.ini

      assertFileContent \
        home-files/.config/systemd/user/fnott.service \
        ${./systemd-user-service-expected.service}
    '';
  };
}

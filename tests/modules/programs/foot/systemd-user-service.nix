{ config, lib, pkgs, ... }:

let
  package = pkgs.writeShellScriptBin "dummy-foot" "" // { outPath = "@foot@"; };
in {
  config = {
    programs.foot = {
      inherit package;
      enable = true;
      server.enable = true;
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/foot/foot.ini

      assertFileContent \
        home-files/.config/systemd/user/foot.service \
        ${./systemd-user-service-expected.service}
    '';
  };
}

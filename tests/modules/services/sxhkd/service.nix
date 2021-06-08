{ config, pkgs, ... }:

let 
  expectedFileRegex = ''
    systemctl --user stop sxhkd.scope 2> /dev/null || true
    systemd-cat -t sxhkd systemd-run --user --scope -u sxhkd \
     @sxhkd@/bin/sxhkd -m 1 &
  '';
in

{
  config = {
    xsession = {
      enable = true;
      windowManager.command = "";
    };

    services.sxhkd = {
      enable = true;
      package = pkgs.runCommandLocal "dummy-package" { } "mkdir $out" // { outPath = "@sxhkd@"; };
      extraOptions = [ "-m 1" ];
    };

    nmt.script = ''
      xsessionFile=home-files/.xsession

      assertFileExists $xsessionFile

      assertFileRegex $xsessionFile ${expectedFileRegex}
    '';
  };
}

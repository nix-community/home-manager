{ config, pkgs, ... }:

{
  config = {
    services.screen-locker = {
      enable = true;
      inactiveInterval = 5;
      lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c AA0000";
      xss-lock = { extraOptions = [ "-test" ]; };
      xautolock = {
        enable = true;
        detectSleep = true;
        extraOptions = [ "-test" ];
      };
    };

    test.stubs.i3lock = { };
    test.stubs.xss-lock = { };

    nmt.script = ''
      xssService=home-files/.config/systemd/user/xss-lock.service
      xautolockService=home-files/.config/systemd/user/xautolock-session.service

      assertFileExists $xssService
      assertFileRegex $xssService 'ExecStart=.*/bin/xss-lock.*-test.*i3lock -n -c AA0000'
      assertFileExists $xautolockService
      assertFileRegex $xautolockService 'ExecStart=.*/bin/xautolock.*-time 5.*-detectsleep.*-test.*'
    '';
  };
}

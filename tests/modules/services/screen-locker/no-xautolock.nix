{ pkgs, ... }:

{
  services.screen-locker = {
    enable = true;
    inactiveInterval = 5;
    lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c AA0000";
    xss-lock = {
      extraOptions = [ "-test" ];
      screensaverCycle = 5;
    };
    xautolock = { enable = false; };
  };

  nmt.script = ''
    xssService=home-files/.config/systemd/user/xss-lock.service

    assertFileExists $xssService
    assertFileRegex $xssService 'ExecStart=.*/bin/xss-lock.*-test.*i3lock -n -c AA0000'
    assertFileRegex $xssService 'ExecStartPre=.*/xset s 300 5'
  '';
}

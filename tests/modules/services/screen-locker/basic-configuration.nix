{ pkgs, ... }:

{
  services.screen-locker = {
    enable = true;
    inactiveInterval = 5;
    lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c AA0000";
    lockCmdEnv = [ "DISPLAY=:0" "XAUTHORITY=/custom/path/.Xauthority" ];
    xss-lock = { extraOptions = [ "-test" ]; };
    xautolock = {
      enable = true;
      detectSleep = true;
      extraOptions = [ "-test" ];
    };
  };

  nmt.script = ''
    xssService=home-files/.config/systemd/user/xss-lock.service
    xautolockService=home-files/.config/systemd/user/xautolock-session.service

    assertFileExists $xssService
    assertFileRegex $xssService 'ExecStart=.*/bin/xss-lock.*-test.*i3lock -n -c AA0000'
    assertFileRegex $xssService 'Environment=DISPLAY=:0'
    assertFileRegex $xssService 'Environment=XAUTHORITY=/custom/path/.Xauthority'
    assertFileRegex $xssService 'Restart=always'
    assertFileExists $xautolockService
    assertFileRegex $xautolockService 'ExecStart=.*/bin/xautolock.*-time 5.*-detectsleep.*-test.*'
    assertFileRegex $xautolockService 'Restart=always'
  '';
}

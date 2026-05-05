{ pkgs, ... }:
{
  home.services.demo = {
    process.argv = [
      "${pkgs.mpd}/bin/mpd"
      "--no-daemon"
    ];
  };

  nmt.script = ''
    assertFileContent home-files/.config/systemd/user/demo.service ${./demo.service}
  '';
}

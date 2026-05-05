{ pkgs, ... }:
{
  home.services."basic" = {
    process.argv = [
      "${pkgs.mpd}/bin/mpd"
      "--no-daemon"
    ];
  };

  nmt.script = ''
    assertFileContent home-files/.config/systemd/user/basic.service ${./basic.service}
  '';
}

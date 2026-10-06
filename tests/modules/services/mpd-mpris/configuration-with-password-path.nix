{
  services.mpd-mpris = {
    enable = true;
    settings.pwd-file = ./mpd-password;
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpd-mpris.service
    assertFileRegex "$serviceFile" \
      '^ExecStart=@mpd-mpris@/bin/mpd-mpris -no-instance -pwd-file /nix/store/[^ ]*/mpd-password$'
  '';
}

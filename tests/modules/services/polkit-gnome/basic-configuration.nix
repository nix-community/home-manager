{
  services.polkit-gnome.enable = true;

  nmt.script = ''
    clientServiceFile=home-files/.config/systemd/user/polkit-gnome.service

    assertFileExists $clientServiceFile
    assertFileContent $clientServiceFile ${builtins.toFile "expected.service" ''
      [Install]
      WantedBy=graphical-session.target

      [Service]
      ExecStart=@polkit-gnome@/libexec/polkit-gnome-authentication-agent-1

      [Unit]
      After=graphical-session-pre.target
      Description=GNOME PolicyKit Agent
      PartOf=graphical-session.target
    ''}
  '';
}

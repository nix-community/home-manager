{
  services.hyprpolkitagent.enable = true;

  nmt.script = ''
    clientServiceFile=home-files/.config/systemd/user/hyprpolkitagent.service

    assertFileExists $clientServiceFile
    assertFileContent $clientServiceFile ${builtins.toFile "expected.service" ''
      [Install]
      WantedBy=graphical-session.target

      [Service]
      ExecStart=@hyprpolkitagent@/libexec/hyprpolkitagent

      [Unit]
      After=graphical-session.target
      Description=Hyprland PolicyKit Agent
      PartOf=graphical-session.target
    ''}
  '';
}

{
  services.flameshot = {
    enable = true;
  };

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/flameshot.service"
    assertFileExists "$serviceFile"
    assertFileContent "$serviceFile" ${builtins.toFile "expected.service" ''
      [Install]
      WantedBy=graphical-session.target

      [Service]
      Environment=PATH=/home/hm-user/.nix-profile/bin
      ExecStart=@flameshot@/bin/flameshot
      LockPersonality=true
      MemoryDenyWriteExecute=true
      NoNewPrivileges=true
      PrivateUsers=true
      Restart=on-abort
      RestrictNamespaces=true
      SystemCallArchitectures=native
      SystemCallFilter=@system-service

      [Unit]
      After=graphical-session.target
      After=tray.target
      Description=Flameshot screenshot tool
      PartOf=graphical-session.target
      Requires=tray.target
    ''}
  '';
}

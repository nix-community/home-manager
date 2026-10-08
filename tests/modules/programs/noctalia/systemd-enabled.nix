{ config, ... }: {
  programs.noctalia = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@noctalia@"; };
    systemd.enable = true;
  };

  nmt.script = ''
    assertFileContent \
    home-files/.config/systemd/user/noctalia.service \
    ${builtins.toFile "noctalia.service" ''
      [Install]
      WantedBy=graphical-session.target

      [Service]
      ExecStart=@noctalia@/bin/dummy
      Restart=on-failure

      [Unit]
      After=graphical-session.target
      Description=Noctalia - A lightweight Wayland shell and bar
      Documentation=https://docs.noctalia.dev/v5/
      PartOf=graphical-session.target
    ''}
  '';
}

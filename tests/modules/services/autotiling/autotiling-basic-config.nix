{ config, ... }:

{
  services.autotiling = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@autotiling@"; };
    extraArgs = [
      "--outputs"
      "DP-1"
      "--workspaces"
      "8"
      "9"
      "--limit"
      "2"
    ];
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/autotiling.service

    assertFileExists "$serviceFile"

    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"

    assertFileContent "$serviceFileNormalized" ${builtins.toFile "expected.service" ''
      [Install]
      WantedBy=graphical-session.target

      [Service]
      ExecStart=@autotiling@/bin/dummy --outputs DP-1 --workspaces 8 9 --limit 2
      Restart=always
      Type=simple

      [Unit]
      After=graphical-session.target
      Description=Split orientation manager
      PartOf=graphical-session.target
    ''}
  '';
}

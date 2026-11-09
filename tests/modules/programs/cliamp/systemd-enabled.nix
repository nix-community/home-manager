{ config, ... }:
{
  programs.cliamp = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@cliamp@"; };
    systemd = {
      enable = true;
      extraFlags = [
        "--auto-play"
        "--playlist"
        "Lofi"
      ];
    };
  };
  nmt.script = ''
    assertFileContent \
    home-files/.config/systemd/user/cliamp.service \
    ${builtins.toFile "cliamp.service" ''
      [Install]
      WantedBy=default.target
      [Service]
      ExecStart=@cliamp@/bin/cliamp --daemon --auto-play --playlist Lofi
      Restart=on-failure
      [Unit]
      Description=cliamp headless music player
    ''}
  '';
}

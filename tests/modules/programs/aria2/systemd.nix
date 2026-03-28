{ config, ... }:
{
  programs.aria2 = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@aria2@"; };
    systemd.enable = true;
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/systemd/user/aria2.service \
      ${builtins.toFile "aria2.service" ''
        [Install]
        WantedBy=default.target

        [Service]
        ExecStart=@aria2@/bin/dummy --enable-rpc
        Restart=on-failure

        [Unit]
        After=default.target
        Description=Aria2c daemon
        Documentation=man:aria2c(1)
        PartOf=default.target
      ''}
  '';
}

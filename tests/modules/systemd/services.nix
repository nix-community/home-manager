{ pkgs, ... }:

let
  drvScript = pkgs.writeShellScript "drv-script.sh" ''
    echo "Just a test"
  '';
in {
  systemd.user.services."test-service@" = {
    Unit = { Description = "A basic test service"; };

    Service = {
      Environment = [ "VAR1=1" "VAR2=2" ];
      ExecStartPre = drvScript;
      ExecStart = ''/some/exec/start/command --with-arguments "%i"'';
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/test-service@.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile \
      ${
        pkgs.writeText "services-expected.conf" ''
          [Service]
          Environment=VAR1=1
          Environment=VAR2=2
          ExecStart=/some/exec/start/command --with-arguments "%i"
          ExecStartPre=${drvScript}

          [Unit]
          Description=A basic test service
        ''
      }
  '';
}

{ config, pkgs, ... }:

{
  config = {
    services.playerctld.enable = true;
    services.playerctld.package = pkgs.writeScriptBin "playerctld" "" // {
      outPath = "@playerctld@";
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/playerctld.service

      assertFileExists "$serviceFile"

      assertFileContent "$serviceFile" "${
        pkgs.writeText "playerctld-test" ''
          [Install]
          WantedBy=default.target

          [Service]
          BusName=org.mpris.MediaPlayer2.playerctld
          ExecStart=@playerctld@/bin/playerctld
          Type=dbus

          [Unit]
          Description=MPRIS media player daemon
        ''
      }"
    '';
  };
}

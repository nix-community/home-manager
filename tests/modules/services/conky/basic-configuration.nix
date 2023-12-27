{ config, pkgs, ... }:

{
  config = {
    services.conky = {
      enable = true;
      settings = ''
        conky.text = [[
          S Y S T E M    I N F O
          $hr
          Host:$alignr $nodename
          Uptime:$alignr $uptime
          RAM:$alignr $mem/$memmax
        ]]
      '';
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/conky.service

      assertFileExists $serviceFile
      assertFileRegex "$serviceFile" 'ExecStart=.*/bin/conky --config .*conky.conf'
      assertFileExists home-files/.config/conky/conky.conf
      assertFileContent "home-files/.config/conky/conky.conf" \
          ${./basic-configuration.conf}
    '';

  };
}

{ config, pkgs, ... }:

{
  config = {
    services.polybar = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-polybar" "";
      script = "polybar bar &";
      config = {
        "bar/top" = {
          monitor = "\${env:MONITOR:eDP1}";
          width = "100%";
          height = "3%";
          radius = 0;
          modules-center = "date";
        };
        "module/date" = {
          type = "internal/date";
          internal = 5;
          date = "%d.%m.%y";
          time = "%H:%M";
          label = "%time%  %date%";
        };
      };
      extraConfig = ''
        [module/date]
        type = internal/date
        interval = 5
        date = "%d.%m.%y"
        time = %H:%M
        format-prefix-foreground = ''${colors.foreground-alt}
        label = %time%  %date%
      '';
    };

    nmt.script = ''
      serviceFile=$home_files/.config/systemd/user/polybar.service

      assertFileExists $serviceFile
      assertFileRegex $serviceFile 'X-Restart-Triggers=.*polybar\.conf'
      assertFileRegex $serviceFile 'ExecStart=.*/bin/polybar-start'

      assertFileExists $home_files/.config/polybar/config
      assertFileContent $home_files/.config/polybar/config \
          ${./basic-configuration.conf}
    '';
  };
}

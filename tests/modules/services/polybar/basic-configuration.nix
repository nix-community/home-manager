{ config, pkgs, ... }:

{
  config = {
    services.polybar = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
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
      settings = {
        "module/volume" = {
          type = "internal/pulseaudio";
          format.volume = "<ramp-volume> <label-volume>";
          label.muted.text = "🔇";
          label.muted.foreground = "#666";
          ramp.volume = [ "🔈" "🔉" "🔊" ];
          click.right = "pavucontrol &";
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
      serviceFile=home-files/.config/systemd/user/polybar.service

      assertFileExists $serviceFile
      assertFileRegex $serviceFile 'X-Restart-Triggers=.*polybar\.conf'
      assertFileRegex $serviceFile 'ExecStart=.*/bin/polybar-start'

      assertFileExists home-files/.config/polybar/config
      assertFileContent home-files/.config/polybar/config \
          ${./basic-configuration.conf}
    '';
  };
}

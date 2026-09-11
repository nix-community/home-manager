{ lib, options, ... }:
{
  services.twmn = {
    enable = true;
    settings.gui = {
      in_animation = 20;
      in_animation_duration = 50;
      out_animation = 25;
      out_animation_duration = 444;
    };
    duration = 4242;
    host = "example.com";
    port = 9006;
    screen = 0;
    soundCommand = "/path/sound/command";
    icons.critical = "/path/icon/critical";
    icons.info = "/path/icon/info";
    icons.warning = "/path/icon/warning";
    text = {
      color = "#FF00FF";
      font.family = "Noto Sans";
      font.size = 16;
      font.variant = "italic";
      maxLength = 80;
    };
    window = {
      alwaysOnTop = true;
      color = "black";
      height = 20;
      offset.x = 20;
      offset.y = -60;
      opacity = 80;
      position = "center";
      animation = {
        easeIn = lib.mkForce {
          curve = 11;
          duration = lib.mkDefault 22;
        };
        easeOut = {
          curve = lib.mkDefault 17;
          duration = lib.mkForce 333;
        };
        bounce.enable = true;
        bounce.duration = 271;
      };
    };
  };

  test.asserts.warnings.expected = [
    "The option `services.twmn.window.animation.easeOut' defined in ${lib.showFiles options.services.twmn.window.animation.easeOut.files} has been changed to `services.twmn.settings' that has a different type. Please read `services.twmn.settings' documentation and update your configuration accordingly."
    "The option `services.twmn.window.animation.easeIn' defined in ${lib.showFiles options.services.twmn.window.animation.easeIn.files} has been changed to `services.twmn.settings' that has a different type. Please read `services.twmn.settings' documentation and update your configuration accordingly."
    "The option `services.twmn.window.offset.y' defined in ${lib.showFiles options.services.twmn.window.offset.y.files} has been changed to `services.twmn.settings' that has a different type. Please read `services.twmn.settings' documentation and update your configuration accordingly."
    "The option `services.twmn.window.offset.x' defined in ${lib.showFiles options.services.twmn.window.offset.x.files} has been changed to `services.twmn.settings' that has a different type. Please read `services.twmn.settings' documentation and update your configuration accordingly."
    "The option `services.twmn.text.maxLength' defined in ${lib.showFiles options.services.twmn.text.maxLength.files} has been changed to `services.twmn.settings' that has a different type. Please read `services.twmn.settings' documentation and update your configuration accordingly."
    "The option `services.twmn.icons.warning' defined in ${lib.showFiles options.services.twmn.icons.warning.files} has been changed to `services.twmn.settings' that has a different type. Please read `services.twmn.settings' documentation and update your configuration accordingly."
    "The option `services.twmn.icons.info' defined in ${lib.showFiles options.services.twmn.icons.info.files} has been changed to `services.twmn.settings' that has a different type. Please read `services.twmn.settings' documentation and update your configuration accordingly."
    "The option `services.twmn.icons.critical' defined in ${lib.showFiles options.services.twmn.icons.critical.files} has been changed to `services.twmn.settings' that has a different type. Please read `services.twmn.settings' documentation and update your configuration accordingly."
    "The option `services.twmn.screen' defined in ${lib.showFiles options.services.twmn.screen.files} has been changed to `services.twmn.settings' that has a different type. Please read `services.twmn.settings' documentation and update your configuration accordingly."
  ]
  ++
    map
      (
        option:
        "The option `services.twmn.${option.old}' defined in ${lib.showFiles (lib.getAttrFromPath (lib.splitString "." option.old) options.services.twmn).files} has been renamed to `services.twmn.settings.${option.new}'."
      )
      [
        {
          old = "window.position";
          new = "gui.position";
        }
        {
          old = "window.opacity";
          new = "gui.opacity";
        }
        {
          old = "window.height";
          new = "gui.height";
        }
        {
          old = "window.color";
          new = "gui.background_color";
        }
        {
          old = "window.animation.bounce.duration";
          new = "gui.bounce_duration";
        }
        {
          old = "window.animation.bounce.enable";
          new = "gui.bounce";
        }
        {
          old = "window.alwaysOnTop";
          new = "gui.always_on_top";
        }
        {
          old = "text.font.variant";
          new = "gui.font_variant";
        }
        {
          old = "text.font.size";
          new = "gui.font_size";
        }
        {
          old = "text.font.family";
          new = "gui.font";
        }
        {
          old = "text.color";
          new = "gui.foreground_color";
        }
        {
          old = "soundCommand";
          new = "main.sound_command";
        }
        {
          old = "port";
          new = "main.port";
        }
        {
          old = "host";
          new = "main.host";
        }
        {
          old = "duration";
          new = "main.duration";
        }
      ];

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/twmnd.service"
    assertFileExists "$serviceFile"
    assertFileRegex "$serviceFile" 'X-Restart-Triggers=.*twmn\.conf'
    assertFileRegex "$serviceFile" 'ExecStart=@twmn@/bin/twmnd'
    assertFileExists "home-files/.config/twmn/twmn.conf"
    assertFileContent "home-files/.config/twmn/twmn.conf" \
        ${./basic-configuration.conf}
  '';
}

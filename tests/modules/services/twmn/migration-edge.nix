{
  config,
  lib,
  options,
  ...
}:
{
  services.twmn = {
    enable = true;
    duration = lib.mkDefault 100;
    port = lib.mkDefault 9000;
    screen = null;
    icons = {
      critical = null;
      info = null;
      warning = null;
    };
    text.maxLength = null;
    window.offset = {
      x = -20;
      y = 7;
    };
    window.animation = {
      easeIn = { config, ... }: {
        duration = config.curve * 2;
      };
      easeOut = { config, ... }: {
        curve = 17;
        duration = config.curve + 316;
      };
    };
    settings = {
      gui.in_animation = 20;
      main.duration = 200;
    };
  };

  assertions = [
    {
      assertion = config.services.twmn.duration == 200;
      message = "legacy duration must read the effective canonical setting";
    }
  ];

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
    "The option `services.twmn.port' defined in ${lib.showFiles options.services.twmn.port.files} has been renamed to `services.twmn.settings.main.port'."
    "The option `services.twmn.duration' defined in ${lib.showFiles options.services.twmn.duration.files} has been renamed to `services.twmn.settings.main.duration'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/twmn/twmn.conf ${./migration-edge.conf}
  '';
}

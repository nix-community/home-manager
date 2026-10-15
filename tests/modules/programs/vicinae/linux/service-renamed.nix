{
  config,
  lib,
  options,
  ...
}:
{
  programs.vicinae = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "vicinae";
      version = "0.21.0";
    };
    systemd = {
      enable = true;
      autoStart = false;
    };
    enableFirefoxIntegration = false;
  };

  test.asserts.warnings.expected = [
    "The option `programs.vicinae.systemd.autoStart' defined in ${lib.showFiles options.programs.vicinae.systemd.autoStart.files} has been renamed to `programs.vicinae.service.autoStart'."
    "The option `programs.vicinae.systemd.enable' defined in ${lib.showFiles options.programs.vicinae.systemd.enable.files} has been renamed to `programs.vicinae.service.enable'."
  ];

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/vicinae.service
    assertFileExists $serviceFile
    assertFileNotRegex $serviceFile '^WantedBy='
  '';
}

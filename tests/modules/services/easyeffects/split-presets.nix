{ config, ... }:

{
  services.easyeffects = {
    enable = true;
    package = config.lib.test.mkStubPackage { version = "8.0.9"; };
    preset = {
      input = "home";
      output = "Discord Voice";
    };
  };

  test.stubs.easyeffects = { };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/easyeffects.service

    assertFileExists "$serviceFile"
    assertFileNotRegex "$serviceFile" 'ExecStart=.*--load-preset'
    assertFileRegex "$serviceFile" \
      'ExecStartPost=.*-easyeffects-load-presets %t/EasyEffectsServer'

    presetLoader=$(sed -n \
      's|^ExecStartPost=-\([^ ]*\).*|\1|p' "$TESTED/$serviceFile")

    assertFileExists "$presetLoader"
    assertFileContains "$presetLoader" \
      "printf '%s\\n' load_preset:input:home"
    assertFileContains "$presetLoader" \
      "printf '%s\\n' 'load_preset:output:Discord Voice'"
    assertFileContains "$presetLoader" \
      'socat -u -T 1 - UNIX-CONNECT:"$preset_socket"'
  '';
}

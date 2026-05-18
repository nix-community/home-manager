{ config, ... }:
{
  services.voxtype = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@voxtype@"; };
    wayland.display = "wayland-1";
    extraArgs = [ "--verbose" ];
    environment.VOXTYPE_TEST_ENV = "1";
    settings = {
      output = {
        mode = "type";
        fallback_to_clipboard = true;
      };
      whisper = {
        model = "base.en";
        language = "en";
      };
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/voxtype.service
    configFile=home-files/.config/voxtype/config.toml

    assertFileExists "$serviceFile"
    assertFileExists "$configFile"

    assertFileRegex "$serviceFile" 'ExecStart=@voxtype@/bin/dummy daemon --verbose'
    assertFileRegex "$serviceFile" 'Environment=PATH=.*/bin'
    assertFileRegex "$serviceFile" 'Environment=WAYLAND_DISPLAY=wayland-1'
    assertFileRegex "$serviceFile" 'Environment=VOXTYPE_TEST_ENV=1'

    assertFileContent "$configFile" ${./expected-config.toml}
  '';
}

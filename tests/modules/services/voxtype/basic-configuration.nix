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

    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
    assertFileContent "$serviceFileNormalized" ${builtins.toFile "expected.service" ''
      [Install]
      WantedBy=default.target

      [Service]
      Environment=PATH=@which@/bin:@wl-clipboard@/bin:@wtype@/bin
      Environment=XDG_RUNTIME_DIR=%t
      Environment=WAYLAND_DISPLAY=wayland-1
      Environment=VOXTYPE_TEST_ENV=1
      ExecStart=@voxtype@/bin/dummy daemon --verbose
      Restart=on-failure
      RestartSec=5s
      Type=exec

      [Unit]
      Description=Voxtype speech-to-text daemon
      PartOf=default.target
      X-Restart-Triggers=/nix/store/00000000000000000000000000000000-voxtype-config.toml
    ''}

    assertFileContent "$configFile" ${./expected-config.toml}
  '';
}

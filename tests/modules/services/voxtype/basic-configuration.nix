{ config, ... }:
{
  services.voxtype = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@voxtype@"; };
    wayland.display = "wayland-1";
    extraArgs = [ "--verbose" ];
    environment.VOXTYPE_TEST_ENV = "1";
    loadModels = [ "base.en" ];
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
    loaderFile=home-files/.config/systemd/user/voxtype-model-loader.service

    assertFileExists "$serviceFile"
    assertFileExists "$configFile"
    assertFileExists "$loaderFile"

    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
    assertFileContent "$serviceFileNormalized" ${builtins.toFile "expected.service" ''
      [Install]
      WantedBy=graphical-session.target

      [Service]
      Environment=PATH=/nix/store/00000000000000000000000000000000-coreutils/bin:@which@/bin:@wl-clipboard@/bin:@wtype@/bin
      Environment=XDG_RUNTIME_DIR=%t
      Environment=WAYLAND_DISPLAY=wayland-1
      Environment=VOXTYPE_TEST_ENV=1
      ExecStart=@voxtype@/bin/dummy daemon --verbose
      Restart=on-failure
      RestartSec=5s
      Type=exec

      [Unit]
      After=graphical-session.target
      Description=Voxtype speech-to-text daemon
      PartOf=graphical-session.target
      Wants=voxtype-model-loader.service
      X-Restart-Triggers=/nix/store/00000000000000000000000000000000-voxtype-config.toml
    ''}

    loaderFileNormalized="$(normalizeStorePaths "$loaderFile")"
    assertFileContent "$loaderFileNormalized" ${builtins.toFile "expected-loader.service" ''
      [Install]
      WantedBy=default.target

      [Service]
      ExecStart=/nix/store/00000000000000000000000000000000-voxtype-model-loader
      RemainAfterExit=true
      Restart=on-failure
      RestartSec=30s
      Type=oneshot

      [Unit]
      After=network-online.target
      Before=voxtype.service
      Description=Download Voxtype models
      Wants=network-online.target
    ''}

    assertFileContent "$configFile" ${./expected-config.toml}
  '';
}

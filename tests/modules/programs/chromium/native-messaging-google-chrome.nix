{ config, pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome;
    nativeMessagingHosts = [
      (config.lib.test.mkStubPackage {
        name = "native-messaging-host";
        buildScript = ''
          mkdir -p $out/etc/chromium/native-messaging-hosts
          echo test > $out/etc/chromium/native-messaging-hosts/com.example.test.json
        '';
      })
    ];
  };

  nmt.script =
    let
      nativeHostsDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/Google/Chrome/NativeMessagingHosts"
        else
          ".config/google-chrome/NativeMessagingHosts";

      chromiumHostsDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/Chromium/NativeMessagingHosts"
        else
          ".config/chromium/NativeMessagingHosts";
    in
    ''
      assertFileExists "home-files/${nativeHostsDir}/com.example.test.json"
      assertPathNotExists "home-files/${chromiumHostsDir}/com.example.test.json"
    '';
}

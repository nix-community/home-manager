# Confirm that both Firefox and Thunderbird can be configured at the same time.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  nativeHostsDir =
    if isDarwin then "Library/Mozilla/NativeMessagingHosts" else ".mozilla/native-messaging-hosts";
in
lib.recursiveUpdate (import ./thunderbird.nix { inherit config lib pkgs; }) {
  programs.thunderbird = {
    nativeMessagingHosts = [
      (config.lib.test.mkStubPackage {
        name = "browserpass";
        buildScript = ''
          mkdir -p $out/lib/mozilla/native-messaging-hosts
          echo test > $out/lib/mozilla/native-messaging-hosts/com.github.browserpass.native.json
        '';
      })
    ];
  };

  nmt.script = ''
    assertFileExists home-files/${nativeHostsDir}/com.github.browserpass.native.json
  '';
}

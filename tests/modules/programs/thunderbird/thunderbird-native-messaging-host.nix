# Confirm that both Firefox and Thunderbird can be configured at the same time.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  nativeHostsDir =
    if isDarwin then "Library/Mozilla/NativeMessagingHosts" else ".mozilla/native-messaging-hosts";
  thunderbirdPackage = config.lib.test.mkStubPackage {
    name = "thunderbird";
    extraAttrs = {
      override =
        f:
        let
          overrides = f { extraPolicies = { }; };
        in
        (config.lib.test.mkStubPackage {
          name = "thunderbird-with-native-host";
          buildScript = ''
            mkdir -p "$out/lib/mozilla/native-messaging-hosts"
            echo wrapped > "$out/lib/mozilla/native-messaging-hosts/com.example.thunderbird-wrapped.json"
          '';
        })
        // {
          inherit (overrides) extraPolicies;
        };
    };
  };
in
lib.recursiveUpdate (import ./thunderbird.nix { inherit config lib pkgs; }) {
  programs.thunderbird = {
    package = thunderbirdPackage;
    nativeMessagingHosts = [
      (config.lib.test.mkStubPackage {
        name = "browserpass";
        buildScript = ''
          mkdir -p $out/lib/mozilla/native-messaging-hosts
          echo test > $out/lib/mozilla/native-messaging-hosts/com.github.browserpass.native.json
        '';
      })
    ];
    policies.DisableTelemetry = true;
  };

  nmt.script = ''
    assertFileExists home-files/${nativeHostsDir}/com.github.browserpass.native.json
    assertFileExists home-files/${nativeHostsDir}/com.example.thunderbird-wrapped.json
  '';
}

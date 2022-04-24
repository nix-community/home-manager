{ lib, ... }:

{
  config = {
    targets.darwin = {
      defaults."com.apple.desktopservices".DSDontWriteNetworkStores = true;
      currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage =
        true;
    };

    nmt.script = ''
      assertFileRegex activate \
        "defaults  import 'com.apple.desktopservices' /nix/store/[a-z0-9]\\{32\\}-com\\.apple\\.desktopservices\\.plist"
      assertFileRegex activate \
        "defaults -currentHost import 'com.apple.controlcenter' /nix/store/[a-z0-9]\\{32\\}-com\\.apple\\.controlcenter\\.plist"
    '';
  };
}

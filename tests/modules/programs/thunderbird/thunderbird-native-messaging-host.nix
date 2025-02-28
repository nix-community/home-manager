# Confirm that both Firefox and Thunderbird can be configured at the same time.
{ lib, realPkgs, ... }:
lib.recursiveUpdate (import ./thunderbird.nix { inherit lib realPkgs; }) {
  programs.thunderbird = {
    nativeMessagingHosts = with realPkgs;
      [
        # NOTE: this is not a real Thunderbird native host module but Firefox; no
        # native hosts are currently packaged for nixpkgs or elsewhere, so we
        # have to improvise. Packaging wise, Firefox and Thunderbird native hosts
        # are identical though. The test doesn't care if the host was meant for
        # either as long as the right paths are present in the package.
        browserpass
      ];
  };

  nmt.script = let
    isDarwin = realPkgs.stdenv.hostPlatform.isDarwin;
    nativeHostsDir = if isDarwin then
      "Library/Mozilla/NativeMessagingHosts"
    else
      ".mozilla/native-messaging-hosts";
  in ''
    assertFileExists home-files/${nativeHostsDir}/com.github.browserpass.native.json
  '';
}

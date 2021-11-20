{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.firefox = {
      enable = true;
      enableGnomeExtensions = true;
    };

    nixpkgs.overlays = [
      (self: super: {
        firefox-unwrapped = pkgs.runCommandLocal "firefox-0" {
          meta.description = "I pretend to be Firefox";
          passthru.gtk3 = null;
        } ''
          mkdir -p "$out"/{bin,lib}
          touch "$out/bin/firefox"
          chmod 755 "$out/bin/firefox"
        '';

        chrome-gnome-shell =
          pkgs.runCommandLocal "dummy-chrome-gnome-shell" { } ''
            mkdir -p $out/lib/mozilla/native-messaging-hosts
            touch $out/lib/mozilla/native-messaging-hosts/dummy
          '';
      })
    ];

    test.asserts.warnings.expected = [''
      Using 'programs.firefox.enableGnomeExtensions' has been deprecated and
      will be removed in the future. Please change to overriding the package
      configuration using 'programs.firefox.package' instead. You can refer to
      its example for how to do this.
    ''];
  };
}

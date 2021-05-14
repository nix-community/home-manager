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
        firefox-unwrapped = pkgs.runCommand "firefox-0" {
          meta.description = "I pretend to be Firefox";
          preferLocalBuild = true;
          allowSubstitutes = false;
        } ''
          mkdir -p "$out/bin"
          touch "$out/bin/firefox"
          chmod 755 "$out/bin/firefox"
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

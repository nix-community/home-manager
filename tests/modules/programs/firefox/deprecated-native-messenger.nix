{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ./setup-firefox-mock-overlay.nix ];

  config = lib.mkIf config.test.enableBig {
    programs.firefox = {
      enable = true;
      enableGnomeExtensions = true;
    };

    test.asserts.warnings.expected = [''
      Using 'programs.firefox.enableGnomeExtensions' has been deprecated and
      will be removed in the future. Please change to overriding the package
      configuration using 'programs.firefox.package' instead. You can refer to
      its example for how to do this.
    ''];
  };
}

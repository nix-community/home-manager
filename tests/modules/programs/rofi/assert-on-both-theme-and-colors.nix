{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.rofi = {
      enable = true;
      theme = "foo";
      colors = {
        window = {
          background = "background";
          border = "border";
          separator = "separator";
        };
        rows = { };
      };
    };

    nixpkgs.overlays =
      [ (self: super: { rofi = pkgs.writeScriptBin "dummy-rofi" ""; }) ];

    test.asserts.assertions.expected = [''
      Cannot use the rofi options 'theme' and 'colors' simultaneously.
    ''];
  };
}

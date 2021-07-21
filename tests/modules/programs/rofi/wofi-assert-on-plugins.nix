{ config, lib, pkgs, ... }:

with lib;

let dummyPackage = x: pkgs.runCommandLocal "dummy-${x}" { } "";
in {
  config = {
    programs.rofi = {
      enable = true;
      package = pkgs.wofi;
      plugins = [ pkgs.rofi-calc ];
    };

    nixpkgs.overlays = [
      (self: super: {
        wofi = dummyPackage "wofi";
        rofi-calc = dummyPackage "rofi-calc";
      })
    ];

    test.asserts.assertions.expected = [''
      Cannot use provided package with plugins.
    ''];
  };
}


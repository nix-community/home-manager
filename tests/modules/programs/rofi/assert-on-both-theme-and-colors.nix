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

    test.stubs.rofi = { };

    test.asserts.assertions.expected = [''
      Cannot use the rofi options 'theme' and 'colors' simultaneously.
    ''];
  };
}

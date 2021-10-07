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

    # Only makes sense to test on older versions
    test.stubs.rofi = { version = "1.6.0"; };

    test.asserts.assertions.expected = [''
      Cannot use the rofi options 'theme' and 'colors' simultaneously.
    ''];
  };
}

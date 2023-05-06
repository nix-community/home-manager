{ config, lib, pkgs, ... }:

{
  config = {
    programs.i3status-rust = { enable = true; };

    test.stubs.i3status-rust = { version = "0.31.1"; };

    test.asserts.assertions.expected = [
      "Only i3status-rust <0.31.0 or ≥0.31.2 is supported due to a config format incompatibility."
    ];
  };
}

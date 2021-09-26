{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.kitty = {
      enable = true;

      darwinLaunchOptions = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin [
        "--single-instance"
        "--directory=/tmp/my-dir"
        "--listen-on=unix:/tmp/my-socket"
      ];

      settings = {
        scrollback_lines = 10000;
        enable_audio_bell = false;
        update_check_interval = 0;
      };

      font.name = "DejaVu Sans";
      font.size = 8;

      keybindings = {
        "ctrl+c" = "copy_or_interrupt";
        "ctrl+f>2" = "set_font_size 20";
      };

      environment = { LS_COLORS = "1"; };
    };

    test.stubs.kitty = { };

    nmt.script = ''
      assertFileExists home-files/.config/kitty/kitty.conf
      assertFileContent \
        home-files/.config/kitty/kitty.conf \
        ${./example-settings-expected.conf}
    '' + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      assertFileContent \
        home-files/.config/kitty/macos-launch-services-cmdline \
        ${./example-macos-launch-services-cmdline}
    '';
  };
}

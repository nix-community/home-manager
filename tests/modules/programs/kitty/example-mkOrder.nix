{ lib, pkgs, ... }:
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
        background_opacity = 0.5;
      };

      font.name = "DejaVu Sans";
      font.size = 8;

      keybindings = {
        "ctrl+c" = "copy_or_interrupt";
        "ctrl+f>2" = "set_font_size 20";
      };

      actionAliases = {
        "launch_tab" = "launch --cwd=current --type=tab";
        "launch_window" = "launch --cwd=current --type=os-window";
      };

      environment = {
        LS_COLORS = "1";
      };

      extraConfig = lib.mkOrder 535 ''
        include ~/.cache/wal/colors-kitty.conf
      '';
    };

    nmt.script = ''
      assertFileExists home-files/.config/kitty/kitty.conf
      assertFileContent \
        home-files/.config/kitty/kitty.conf \
        ${./example-mkOrder-expected.conf}
    '';
  };
}

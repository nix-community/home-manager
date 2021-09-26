{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.sm64ex = {
      enable = true;

      settings = {
        fullscreen = true;
        window_x = 0;
        window_y = 0;
        window_w = 1920;
        window_h = 1080;
        vsync = 1;
        texture_filtering = 1;
        master_volume = 127;
        music_volume = 127;
        sfx_volume = 127;
        env_volume = 127;
        key_a = [ "0026" "1000" "1103" ];
        key_b = [ "0033" "1002" "1101" ];
        key_start = [ "0039" "1006" "ffff" ];
        key_l = [ "0034" "1007" "1104" ];
        key_r = [ "0036" "100a" "1105" ];
        key_z = [ "0025" "1009" "1102" ];
        key_cup = [ "100b" "ffff" "ffff" ];
        key_cdown = [ "100c" "ffff" "ffff" ];
        key_cleft = [ "100d" "ffff" "ffff" ];
        key_cright = [ "100e" "ffff" "ffff" ];
        key_stickup = [ "0011" "ffff" "ffff" ];
        key_stickdown = [ "001f" "ffff" "ffff" ];
        key_stickleft = [ "001e" "ffff" "ffff" ];
        key_stickright = [ "0020" "ffff" "ffff" ];
        stick_deadzone = 16;
        rumble_strength = 10;
        skip_intro = 1;
      };
    };

    test.stubs.sm64ex = { };

    nmt.script = ''
      assertFileContent \
        home-files/.local/share/sm64pc/sm64config.txt \
        ${
          pkgs.writeText "sm64ex-expected-settings" ''
            env_volume 127
            fullscreen true
            key_a 0026 1000 1103
            key_b 0033 1002 1101
            key_cdown 100c ffff ffff
            key_cleft 100d ffff ffff
            key_cright 100e ffff ffff
            key_cup 100b ffff ffff
            key_l 0034 1007 1104
            key_r 0036 100a 1105
            key_start 0039 1006 ffff
            key_stickdown 001f ffff ffff
            key_stickleft 001e ffff ffff
            key_stickright 0020 ffff ffff
            key_stickup 0011 ffff ffff
            key_z 0025 1009 1102
            master_volume 127
            music_volume 127
            rumble_strength 10
            sfx_volume 127
            skip_intro 1
            stick_deadzone 16
            texture_filtering 1
            vsync 1
            window_h 1080
            window_w 1920
            window_x 0
            window_y 0''
        }
    '';
  };
}

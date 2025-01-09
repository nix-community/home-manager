{ config, pkgs, ... }:

{
  config = {
    programs.mangohud = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      settings = {
        output_folder = /home/user/Documents/mangohud;
        fps_limit = [ 30 60 ];
        vsync = 0;
        legacy_layout = false;
        cpu_stats = true;
        cpu_temp = true;
        cpu_power = true;
        cpu_text = "CPU";
        cpu_mhz = true;
        cpu_load_change = true;
        cpu_load_value = true;
        media_player_name = "spotify";
        media_player_order = [ "title" "artist" "album" ];
      };
      settingsPerApplication = {
        mpv = {
          output_folder = /home/user/Documents/mpv-mangohud;
          no_display = true;
        };
      };
      extraConfig = ''

        ### Display the current GPU information
        gpu_stats
        gpu_temp
        gpu_core_clock
        gpu_mem_clock
        gpu_power

        # gpu_text=GPU
        # gpu_load_change
        # gpu_load_value=60,90
        # gpu_load_color=39F900,FDFD09,B22222

      '';
    };

    nmt.script = ''
      assertFileExists home-files/.config/MangoHud/MangoHud.conf
      assertFileContent home-files/.config/MangoHud/MangoHud.conf \
          ${./basic-configuration.conf}
      assertFileExists home-files/.config/MangoHud/mpv.conf
      assertFileContent home-files/.config/MangoHud/mpv.conf \
          ${./basic-configuration-mpv.conf}
    '';
  };
}

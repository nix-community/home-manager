{ config, ... }:

{
  programs.btop = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      # Integer
      update_ms = 1000;

      # Boolean
      show_io_stat = false;
      io_graph_combined = true;

      # String
      disks_filter = "exclude=/foo/bar";
      log_level = "DEBUG";

      # Empty string
      io_graph_speeds = "";
    };

    extraConfig = ''
      clock_format = "%H:%M"
    '';

    themes.example = ''
      theme[main_bg]="#282a36"
      theme[main_fg]="#f8f8f2"
      theme[title]="#f8f8f2"
      theme[hi_fg]="#6272a4"
      theme[selected_bg]="#ff79c6"
      theme[selected_fg]="#f8f8f2"
      theme[inactive_fg]="#44475a"
      theme[graph_text]="#f8f8f2"
      theme[meter_bg]="#44475a"
      theme[proc_misc]="#bd93f9"
      theme[cpu_box]="#bd93f9"
      theme[mem_box]="#50fa7b"
      theme[net_box]="#ff5555"
      theme[proc_box]="#8be9fd"
      theme[div_line]="#44475a"
      theme[temp_start]="#bd93f9"
      theme[temp_mid]="#ff79c6"
      theme[temp_end]="#ff33a8"
      theme[cpu_start]="#bd93f9"
      theme[cpu_mid]="#8be9fd"
      theme[cpu_end]="#50fa7b"
      theme[free_start]="#ffa6d9"
      theme[free_mid]="#ff79c6"
      theme[free_end]="#ff33a8"
      theme[cached_start]="#b1f0fd"
      theme[cached_mid]="#8be9fd"
      theme[cached_end]="#26d7fd"
      theme[available_start]="#ffd4a6"
      theme[available_mid]="#ffb86c"
      theme[available_end]="#ff9c33"
      theme[used_start]="#96faaf"
      theme[used_mid]="#50fa7b"
      theme[used_end]="#0dfa49"
      theme[download_start]="#bd93f9"
      theme[download_mid]="#50fa7b"
      theme[download_end]="#8be9fd"
      theme[upload_start]="#8c42ab"
      theme[upload_mid]="#ff79c6"
      theme[upload_end]="#ff33a8"
      theme[process_start]="#50fa7b"
      theme[process_mid]="#59b690"
      theme[process_end]="#6272a4"
    '';
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/btop/btop.conf \
      ${./example-settings-expected.conf}
    assertFileContent \
      home-files/.config/btop/themes/example.theme \
      ${./example-theme-expected.theme}
  '';
}

{ pkgs, ... }:
{
  programs.macchina = {
    enable = true;
    package = pkgs.writeScriptBin "dummy-macchina" "";

    themes = {
      Hydrogen = {
        spacing = 2;
        padding = 1;
        hide_ascii = true;
        prefer_small_ascii = true;
        separator = ">";
        key_color = "Cyan";
        separator_color = "White";

        palette = {
          type = "Full";
          glyph = "() ";
          visible = true;
        };

        bar = {
          glyph = "o";
          symbol_open = "[";
          symbol_close = "]";
          hide_delimiters = true;
          visible = true;
        };

        box = {
          title = "Hydrogen";
          border = "rounded";
          visible = true;
          inner_margin = {
            x = 1;
            y = 0;
          };
        };

        custom_ascii = {
          color = "Cyan";
          path = "~/ascii/arch_linux";
        };

        randomize = {
          key_color = false;
          separator_color = true;
        };

        keys = {
          host = "Host";
          kernel = "Kernel";
          os = "OS";
          machine = "Machine";
          de = "DE";
          wm = "WM";
          distro = "Distro";
          terminal = "Terminal";
          shell = "Shell";
          packages = "Packages";
          uptime = "Uptime";
          local_ip = "Local IP";
          memory = "Memory";
          battery = "Battery";
          backlight = "Brightness";
          resolution = "Resolution";
          cpu = "CPU";
          cpu_load = "CPU Load";
          gpu = "GPU";
          disk_space = "Disk Space";
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/macchina/themes/Hydrogen.toml
    assertFileContent \
      home-files/.config/macchina/themes/Hydrogen.toml \
      ${./full-theme-expected.toml}
  '';
}

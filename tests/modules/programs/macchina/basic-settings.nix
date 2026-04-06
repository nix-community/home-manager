{ pkgs, ... }:
{
  programs.macchina = {
    enable = true;
    package = pkgs.writeScriptBin "dummy-macchina" "";

    settings = {
      long_uptime = true;
      long_shell = true;
      long_kernel = false;
      current_shell = false;
      physical_cores = false;
      disks = [
        "/"
        "/home"
      ];
      disk_space_percentage = true;
      memory_percentage = true;
      theme = "Hydrogen";
      show = [
        "Memory"
        "Processor"
        "Shell"
        "Uptime"
      ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/macchina/macchina.toml
    assertFileContent \
      home-files/.config/macchina/macchina.toml \
      ${./basic-settings-expected.toml}
  '';
}

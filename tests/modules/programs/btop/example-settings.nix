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
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/btop/btop.conf \
      ${./example-settings-expected.conf}
  '';
}

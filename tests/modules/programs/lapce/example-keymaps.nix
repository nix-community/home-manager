{ config, ... }:

{
  programs.lapce = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    keymaps = [{
      command = "open_log_file";
      key = "Ctrl+Shift+L";
    }];
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/lapce-stable/keymaps.toml \
      ${./example-keymaps-expected.toml}
  '';
}

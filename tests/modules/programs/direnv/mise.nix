{ config, ... }:

{
  programs.bash.enable = true;
  programs.direnv = {
    enable = true;
    mise = {
      enable = true;
      package = config.lib.test.mkStubPackage { name = "mise"; };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileExists home-files/.config/direnv/lib/hm-mise.sh
  '';
}

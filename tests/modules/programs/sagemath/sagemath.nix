{ config, ... }:

{
  programs.sagemath = {
    enable = true;
    configDir = "${config.xdg.configHome}/sage";
    dataDir = "${config.xdg.dataHome}/sage";
    initScript = ''
      %colors linux
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/sage/init.sage
    assertFileContent home-files/.config/sage/init.sage \
      ${./init-expected.sage}
  '';
}

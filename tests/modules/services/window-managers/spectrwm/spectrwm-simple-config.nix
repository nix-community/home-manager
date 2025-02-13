{
  xsession.windowManager.spectrwm = {
    enable = true;
    settings = {
      bar_enabled = true;
      bar_format = "+S [+R:+I] %a %b %d [%R]";
      bar_justify = "center";
      modkey = "Mod4";
    };
    programs = { term = "alacritty"; };
    bindings = { term = "MOD+Shift+Return"; };
    unbindings = [ "MOD+Return" ];
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/spectrwm/spectrwm.conf ${
        ./spectrwm-simple-config-expected-spectrwm.conf
      }
  '';
}

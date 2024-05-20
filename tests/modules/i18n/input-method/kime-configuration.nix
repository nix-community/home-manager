{ config, pkgs, ... }:

let

  kimeConfig = ''
    daemon:
      modules: [Xim,Indicator]
    indicator:
      icon_color: White
    engine:
      hangul:
        layout: dubeolsik
  '';

in {
  i18n.inputMethod = {
    enabled = "kime";
    kime.extraConfig = kimeConfig;
  };

  test.stubs = {
    kime = { outPath = null; };
    gtk2 = {
      buildScript = ''
        mkdir -p $out/bin
        echo '#/usr/bin/env bash' > $out/bin/gtk-query-immodules-2.0
        chmod +x $out/bin/*
      '';
    };
    gtk3 = {
      buildScript = ''
        mkdir -p $out/bin
        echo '#/usr/bin/env bash' > $out/bin/gtk-query-immodules-3.0
        chmod +x $out/bin/*
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/kime-daemon.service
    assertFileExists home-files/.config/kime/config.yaml
    assertFileContent home-files/.config/kime/config.yaml \
      ${builtins.toFile "kime-expected.yaml" kimeConfig}
  '';
}

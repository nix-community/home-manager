{
  test.stubs = {
    fcitx5 = {
      version = "0";
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin $out/share/applications $out/etc/xdg/autostart
        touch $out/bin/fcitx5 \
              $out/bin/fcitx5-config-qt \
              $out/share/applications/org.fcitx.Fcitx5.desktop \
              $out/etc/xdg/autostart/org.fcitx.Fcitx5.desktop
        chmod +x $out/bin/fcitx5 \
                 $out/bin/fcitx5-config-qt
      '';
    };
    fcitx5-lua = { outPath = null; };
    fcitx5-gtk = { outPath = null; };

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

  nixpkgs.overlays = [
    (final: prev: {
      libsForQt5 = prev.libsForQt5.overrideScope (qt5final: qt5prev: {
        fcitx5-chinese-addons = prev.mkStubPackage { outPath = null; };
        fcitx5-configtool = prev.mkStubPackage { outPath = null; };
        fcitx5-qt = prev.mkStubPackage { outPath = null; };

        fcitx5-with-addons = qt5prev.fcitx5-with-addons.override {
          inherit (final) libsForQt5 qt6Packages;
        };
      });

      qt6Packages = prev.qt6Packages.overrideScope (qt6final: qt6prev: {
        fcitx5-qt = prev.mkStubPackage { outPath = null; };
      });

    })
  ];
}

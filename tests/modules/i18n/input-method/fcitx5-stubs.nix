{
  test.stubs = {
    fcitx5 = {
      version = "0";
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin $out/share/applications $out/share/dbus-1/services $out/etc/xdg/autostart
        touch $out/bin/fcitx5 \
              $out/bin/fcitx5-config-qt \
              $out/share/applications/org.fcitx.Fcitx5.desktop \
              $out/share/dbus-1/services/org.fcitx.Fcitx5.service \
              $out/etc/xdg/autostart/org.fcitx.Fcitx5.desktop
        # The grep usage of fcitx5-with-addons expects one of the files to match with the fcitx5.out
        # https://github.com/NixOS/nixpkgs/blob/d2eb4be48705289791428c07aca8ff654c1422ba/pkgs/tools/inputmethods/fcitx5/with-addons.nix#L40-L44
        echo $out >> $out/etc/xdg/autostart/org.fcitx.Fcitx5.desktop
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

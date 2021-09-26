{
  test.stubs = {
    fcitx5 = {
      version = "0";
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin $out/share/applications $out/etc/xdg/autostart
        touch $out/bin/fcitx5 \
              $out/share/applications/org.fcitx.Fcitx5.desktop \
              $out/etc/xdg/autostart/org.fcitx.Fcitx5.desktop
        chmod +x $out/bin/fcitx5
      '';
    };
    fcitx5-configtool = { outPath = null; };
    fcitx5-lua = { outPath = null; };
    fcitx5-qt = { outPath = null; };
    fcitx5-gtk = { outPath = null; };
    fcitx5-chinese-addons = { outPath = null; };
  };

  nixpkgs.overlays = [
    (self: super: {
      fcitx5-with-addons =
        super.fcitx5-with-addons.override { inherit (self) fcitx5-qt; };
    })
  ];
}

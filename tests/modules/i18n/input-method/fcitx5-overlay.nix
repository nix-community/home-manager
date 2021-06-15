final: prev:

let

  dummy = prev.runCommandLocal "dummy-package" { } "mkdir $out";

in {
  fcitx5 = prev.runCommandLocal "fcitx5" { version = "0"; } ''
    mkdir -p $out/bin $out/share/applications $out/etc/xdg/autostart
    touch $out/bin/fcitx5 \
          $out/share/applications/org.fcitx.Fcitx5.desktop \
          $out/etc/xdg/autostart/org.fcitx.Fcitx5.desktop
    chmod +x $out/bin/fcitx5
  '';
  fcitx5-configtool = dummy;
  fcitx5-lua = dummy;
  fcitx5-qt = dummy;
  fcitx5-gtk = dummy;
  fcitx5-with-addons =
    prev.fcitx5-with-addons.override { inherit (final) fcitx5-qt; };
  fcitx5-chinese-addons = dummy;
}

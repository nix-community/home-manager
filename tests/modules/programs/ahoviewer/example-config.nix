{ pkgs, ... }:

{
  programs.ahoviewer = {
    enable = true;
    config = ''
      ZoomMode = "M";
      Geometry :
      {
          x = 964;
          y = 574;
          w = 948;
          h = 498;
      };
      BooruWidth = 382;
      TagViewPosition = 318;
      SmartNavigation = true;
      StoreRecentFiles = false;
      RememberLastFile = false;
      SaveThumbnails = false;
      AutoOpenArchive = false;
      BooruBrowserVisible = true;
    '';
    plugins = [
      (pkgs.callPackage ./plugins/a.nix { })
      (pkgs.callPackage ./plugins/b.nix { })
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/ahoviewer/ahoviewer.cfg
    assertFileContent home-files/.config/ahoviewer/ahoviewer.cfg \
      ${./ahoviewer.cfg}

    assertFileExists home-files/.local/share/ahoviewer/plugins/plugin-a/plugin-a.plugin
    assertFileExists home-files/.local/share/ahoviewer/plugins/plugin-a/plugin-a.py

    assertFileExists home-files/.local/share/ahoviewer/plugins/plugin-a/plugin-a.plugin
    assertFileExists home-files/.local/share/ahoviewer/plugins/plugin-a/plugin-a.py
  '';
}

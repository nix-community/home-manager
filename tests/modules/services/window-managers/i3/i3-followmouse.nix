{
  xsession.windowManager.i3 = {
    enable = true;

    config.focus.followMouse = false;
  };

  nixpkgs.overlays = [
    (self: super: {
      dmenu = super.dmenu // { outPath = "@dmenu@"; };

      i3 = super.writeScriptBin "i3" "" // { outPath = "@i3@"; };

      i3-gaps = super.writeScriptBin "i3" "" // { outPath = "@i3-gaps@"; };

      i3status = super.i3status // { outPath = "@i3status@"; };
    })
  ];

  nmt.script = ''
    assertFileExists home-files/.config/i3/config
    assertFileContent home-files/.config/i3/config \
      ${./i3-followmouse-expected.conf}
  '';
}

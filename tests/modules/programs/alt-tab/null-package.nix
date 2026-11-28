{
  config,
  pkgs,
  realPkgs,
  ...
}:

{
  programs.altTab = {
    enable = true;
    package = null;
    spacesToShow = "visible";
    shortcut = "Control+Option+Space";
  };

  assertions = [
    {
      assertion = !(builtins.elem pkgs.alt-tab-macos config.home.packages);
      message = "A null package must not install AltTab.";
    }
  ];

  nmt.script = ''
    plist=$(grep -oE '/nix/store/[a-z0-9]+-com[.]lwouis[.]alt-tab-macos[.]plist' "$TESTED/activate")
    assertFileContent "$plist" ${./visible-spaces.plist}
    shortcut=$(grep -oE '/nix/store/[a-z0-9]+-alttab-shortcut[.]plist' "$TESTED/activate")
    assertFileExists "$shortcut"
    ${realPkgs.python3}/bin/python ${./check-shortcut.py} "$shortcut" 786432 49 ' '
  '';
}

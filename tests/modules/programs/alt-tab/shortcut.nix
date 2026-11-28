{ config, realPkgs, ... }:

{
  programs.altTab = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "custom-alttab"; };
    spacesToShow = "visible";
    shortcut = "Command+Tab";
  };

  assertions = [
    {
      assertion = builtins.elem config.programs.altTab.package config.home.packages;
      message = "AltTab must install the custom package.";
    }
  ];

  nmt.script = ''
    plist=$(grep -oE '/nix/store/[a-z0-9]+-com[.]lwouis[.]alt-tab-macos[.]plist' "$TESTED/activate")
    assertFileContent "$plist" ${./visible-spaces.plist}

    shortcut=$(grep -oE '/nix/store/[a-z0-9]+-alttab-shortcut[.]plist' "$TESTED/activate")
    assertFileContent "$shortcut" ${./command-tab.plist}
    ${realPkgs.python3}/bin/python ${./check-shortcut.py} "$shortcut"
  '';
}

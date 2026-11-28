{ config, ... }:

{
  programs.altTab.enable = true;

  assertions = [
    {
      assertion = builtins.elem config.programs.altTab.package config.home.packages;
      message = "AltTab must install the configured package.";
    }
  ];

  nmt.script = ''
    plist=$(grep -oE '/nix/store/[a-z0-9]+-com[.]lwouis[.]alt-tab-macos[.]plist' "$TESTED/activate")
    assertFileContent "$plist" ${./all-spaces.plist}
    assertFileNotRegex activate 'alttab-shortcut[.]plist'
  '';
}

{ config, pkgs, ... }:

{
  programs.altTab = {
    enable = false;
    spacesToShow = "visible";
    shortcut = "Command+Tab";
  };

  assertions = [
    {
      assertion = !(builtins.elem pkgs.alt-tab-macos config.home.packages);
      message = "Disabled AltTab must not install its package.";
    }
  ];

  nmt.script = ''
    assertFileNotRegex activate 'com[.]lwouis[.]alt-tab-macos'
    assertFileNotRegex activate 'alttab-shortcut[.]plist'
  '';
}

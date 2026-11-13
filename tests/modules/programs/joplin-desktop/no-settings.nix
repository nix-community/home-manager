{ config, ... }:
{
  programs.joplin-desktop.enable = true;

  nmt.script =
    assert !(config.home.activation ? activateJoplinDesktopConfig);
    assert builtins.elem config.programs.joplin-desktop.package config.home.packages;
    ''
      assertFileNotRegex activate 'activateJoplinDesktopConfig|joplin-settings.json'
      assertPathNotExists home-files/.config/joplin-desktop/settings.json
    '';
}

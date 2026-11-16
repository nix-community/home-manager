{
  config,
  lib,
  options,
  ...
}:
{
  programs.joplin-desktop = {
    enable = true;
    sync.target = "dropbox";
    settings = lib.mkForce { };
  };
  test.asserts.warnings.expected = (import ./warnings.nix { inherit lib options; }) [
    [
      "sync"
      "target"
    ]
  ];
  nmt.script =
    assert config.programs.joplin-desktop.general.editor == null;
    ''
      assertFileNotRegex activate 'activateJoplinDesktopConfig|joplin-settings.json'
      assertPathNotExists home-files/.config/joplin-desktop/settings.json
    '';
}

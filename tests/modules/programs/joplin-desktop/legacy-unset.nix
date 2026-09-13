{
  config,
  lib,
  options,
  ...
}:
{
  programs.joplin-desktop = {
    enable = true;
    general.editor = lib.mkOverride 1600 "kate";
    extraConfig = lib.mkOverride 1600 { newNoteFocus = "title"; };
    sync.target = lib.mkDefault "undefined";
  };
  test.asserts.warnings.expected = (import ./warnings.nix { inherit lib options; }) [
    [
      "sync"
      "target"
    ]
  ];
  nmt.script =
    assert config.programs.joplin-desktop.sync.target == "undefined";
    assert config.programs.joplin-desktop.sync.interval == "undefined";
    ''
      assertFileNotRegex activate 'activateJoplinDesktopConfig|joplin-settings.json'
      assertPathNotExists home-files/.config/joplin-desktop/settings.json
    '';
}

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
      generated="$(grep -o '/nix/store/.*-joplin-settings.json' $TESTED/activate)"
      diff -u "$generated" ${./empty.json}
    '';
}

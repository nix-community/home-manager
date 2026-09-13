{
  config,
  lib,
  options,
  ...
}:
{
  programs.joplin-desktop = {
    enable = true;
    general.editor = lib.mkForce "kate";
    sync.target = "dropbox";
    sync.interval = "10m";
    extraConfig = lib.mkForce {
      editor = "nano";
      "sync.target" = 0;
      newNoteFocus = "title";
      conditional = lib.mkIf true (lib.mkDefault "fallback");
      "sync.interval" = lib.mkIf false 0;
    };
    settings.conditional = "canonical";
  };

  test.asserts.warnings.expected =
    (import ./warnings.nix { inherit lib options; }) [
      [
        "general"
        "editor"
      ]
      [
        "sync"
        "target"
      ]
      [
        "sync"
        "interval"
      ]
    ]
    ++ [
      "The option `programs.joplin-desktop.extraConfig' defined in ${lib.showFiles options.programs.joplin-desktop.extraConfig.files} has been renamed to `programs.joplin-desktop.settings'."
    ];

  nmt.script =
    assert config.programs.joplin-desktop.general.editor == "nano";
    assert config.programs.joplin-desktop.sync.interval == "10m";
    ''
      generated="$(grep -o '/nix/store/.*-joplin-settings.json' $TESTED/activate)"
      diff -u "$generated" ${./extra-config-root-force.json}
    '';
}

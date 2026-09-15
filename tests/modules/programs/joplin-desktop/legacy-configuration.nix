{ lib, options, ... }:
{
  imports = [
    { programs.joplin-desktop.general.editor = lib.mkDefault "nano"; }
  ];
  programs.joplin-desktop = {
    enable = true;
    general.editor = lib.mkForce "kate";
    sync.target = lib.mkDefault "dropbox";
    sync.interval = lib.mkDefault "10m";
    extraConfig = lib.mkDefault {
      "sync.target" = 0;
      falseValue = false;
      zeroValue = 0;
      newNoteFocus = "title";
      composed = {
        value = lib.mkDefault "legacy";
        list = lib.mkAfter [ "last" ];
        retained = true;
      };
    };
    settings = {
      modern = true;
      "sync.interval" = 0;
      composed = lib.mkDefault {
        value = "canonical";
        list = [ "first" ];
      };
    };
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

  nmt.script = ''
    generated="$(grep -o '/nix/store/.*-joplin-settings.json' $TESTED/activate)"
    diff -u "$generated" ${./legacy-configuration.json}
  '';
}

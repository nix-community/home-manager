mode:

{ config, lib, ... }:

let
  mutable = mode == "mutable";
  disabled = mode == "disabled";
  cleanup = config.home.activation.zedImmutableConfig or null;
  files = [
    "settings"
    "keymap"
    "tasks"
    "debug"
  ];
  # The disabled mode turns off one file through each option path and keeps
  # the others, so only the enabled entries get a cleanup.
  disabledFiles = lib.optionals disabled [
    "settings"
    "keymap"
  ];
  linkedFiles = lib.subtractLists disabledFiles files;
  cleansUp = name: cleanup != null && lib.hasInfix ".config/zed/${name}.json" cleanup.data;
in
{
  programs.zed-editor = {
    enable = true;
    mutableUserSettings = mutable;
    mutableUserKeymaps = mutable;
    mutableUserTasks = mutable;
    mutableUserDebug = mutable;
    userSettings = {
      theme = "XY-Zed";
      vim_mode = false;
    };
    userKeymaps = [
      {
        context = "Editor";
        bindings.ctrl-s = "workspace::Save";
      }
    ];
    userTasks = [
      {
        label = "Build";
        command = "nix build";
      }
    ];
    userDebug = [
      {
        label = "Debug";
        adapter = "CodeLLDB";
      }
    ];
  };

  home.file = lib.mkIf disabled {
    "${config.xdg.configHome}/zed/settings.json".enable = lib.mkForce false;
  };
  xdg.configFile = lib.mkIf disabled {
    "zed/keymap.json".enable = false;
  };

  # Which files get a cleanup and where it runs; the removal itself is covered
  # by the mkImpureConfigCleanup tests.
  nmt.script =
    assert (cleanup != null) == !mutable;
    assert
      cleanup == null || (cleanup.after == [ "writeBoundary" ] && cleanup.before == [ "linkGeneration" ]);
    assert lib.all cleansUp (lib.optionals (!mutable) linkedFiles);
    assert !lib.any cleansUp disabledFiles;
    lib.concatMapStrings (
      name:
      if mutable || lib.elem name disabledFiles then
        ''
          assertPathNotExists "home-files/.config/zed/${name}.json"
        ''
      else
        ''
          assertFileExists "home-files/.config/zed/${name}.json"
        ''
    ) files;
}

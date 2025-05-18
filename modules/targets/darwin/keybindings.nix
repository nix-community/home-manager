{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.targets.darwin;
  homeDir = config.home.homeDirectory;
  confFile = pkgs.writeText "DefaultKeybinding.dict" (lib.generators.toPlist { } cfg.keybindings);
in
{
  options.targets.darwin.keybindings = lib.mkOption {
    type = with lib.types; attrsOf anything;
    default = { };
    example = {
      "^u" = "deleteToBeginningOfLine:";
      "^w" = "deleteWordBackward:";
    };
    description = ''
      This will configure the default keybindings for text fields in macOS
      applications. See
      [Apple's documentation](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/TextDefaultsBindings/TextDefaultsBindings.html)
      for more details.

      ::: {.warning}
      Existing keybinding configuration will be wiped when using this
      option.
      :::
    '';
  };

  config = lib.mkIf (cfg.keybindings != { }) {
    assertions = [
      (lib.hm.assertions.assertPlatform "targets.darwin.keybindings" pkgs lib.platforms.darwin)
    ];

    # NOTE: just copy the files because symlinks won't be recognized by macOS
    home.activation.setCocoaKeybindings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      verboseEcho "Configuring keybindings for the Cocoa Text System"
      run install -Dm644 $VERBOSE_ARG \
        "${confFile}" "${homeDir}/Library/KeyBindings/DefaultKeyBinding.dict"
    '';
  };
}

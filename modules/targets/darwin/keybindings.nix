{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.targets.darwin;
  homeDir = config.home.homeDirectory;
  confFile = pkgs.writeText "DefaultKeybinding.dict"
    (lib.generators.toPlist { } cfg.keybindings);
in {
  options.targets.darwin.keybindings = mkOption {
    type = with types; attrsOf anything;
    default = { };
    example = {
      "^u" = "deleteToBeginningOfLine:";
      "^w" = "deleteWordBackward:";
    };
    description = ''
      This will configure the default keybindings for text fields in macOS
      applications. See
      <link xlink:href="https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/TextDefaultsBindings/TextDefaultsBindings.html">Apple's documentation</link>
      for more details.

      <warning>
        <para>
          Existing keybinding configuration will be wiped when using this
          option.
        </para>
      </warning>
    '';
  };

  config = mkIf (cfg.keybindings != { }) {
    assertions = [
      (hm.assertions.assertPlatform "targets.darwin.keybindings" pkgs
        platforms.darwin)
    ];

    # NOTE: just copy the files because symlinks won't be recognized by macOS
    home.activation.setCocoaKeybindings =
      hm.dag.entryAfter [ "writeBoundary" ] ''
        $VERBOSE_ECHO "Configuring keybindings for the Cocoa Text System"
        $DRY_RUN_CMD install -Dm644 $VERBOSE_ARG \
          "${confFile}" "${homeDir}/Library/KeyBindings/DefaultKeyBinding.dict"
      '';
  };
}

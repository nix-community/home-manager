{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.altTab;

  shortcutType =
    lib.types.addCheck
      (lib.types.strMatching (
        "((Command|Control|Option|Shift)\\+)+"
        + "([A-Za-z0-9]|F([1-9]|1[0-9]|20)|Tab|Space|Return|Escape|Backspace|Delete|"
        + "Home|End|PageUp|PageDown|Left|Right|Up|Down|Minus|Equal|LeftBracket|"
        + "RightBracket|Backslash|Semicolon|Quote|Comma|Period|Slash|Grave)"
      ))
      (
        value:
        let
          modifiers = lib.init (lib.splitString "+" value);
        in
        lib.length modifiers == lib.length (lib.unique modifiers)
      );

  shortcutPlist =
    pkgs.runCommand "alttab-shortcut.plist"
      {
        nativeBuildInputs = [ pkgs.buildPackages.python3 ];
        inherit (cfg) shortcut;
      }
      ''
        python ${./shortcut.py} "$shortcut" "$out"
      '';
in
{
  meta.maintainers = [ lib.hm.maintainers.NikoPit ];

  options.programs.altTab = {
    enable = lib.mkEnableOption "AltTab, a macOS window switcher";

    package = lib.mkPackageOption pkgs "alt-tab-macos" { nullable = true; };

    spacesToShow = lib.mkOption {
      type = lib.types.enum [
        "all"
        "visible"
      ];
      default = "all";
      example = "visible";
      description = ''
        Spaces whose windows appear when using AltTab's first shortcut.
        With multiple displays, `visible` includes the visible Space on
        each display.

        Home Manager reapplies this preference during activation. Restart
        AltTab after activation to load the configured preferences.
      '';
    };

    shortcut = lib.mkOption {
      type = lib.types.nullOr shortcutType;
      default = null;
      example = "Command+Tab";
      description = ''
        Activation shortcut for AltTab's first shortcut. A null value leaves
        the existing shortcut unchanged.

        Separate modifiers and the key with `+`. Supported modifiers are
        `Command`, `Control`, `Option`, and `Shift`. Keys are letters,
        digits, `F1` through `F20`, `Tab`, `Space`, `Return`, `Escape`,
        `Backspace`, `Delete`, `Home`, `End`, `PageUp`, `PageDown`,
        `Left`, `Right`, `Up`, `Down`, `Minus`, `Equal`, `LeftBracket`,
        `RightBracket`, `Backslash`, `Semicolon`, `Quote`, `Comma`,
        `Period`, `Slash`, and `Grave`. Keys refer to US ANSI positions.

        The shortcut is encoded in AltTab's archived ShortcutRecorder
        format, as used by AltTab 11.7.1. Home Manager reapplies it during
        activation. Restart AltTab to load the new shortcut.

        macOS Accessibility permission must be granted manually. Window
        thumbnails also require Screen Recording permission.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.altTab" pkgs lib.platforms.darwin)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    targets.darwin.defaults."com.lwouis.alt-tab-macos".spacesToShow =
      if cfg.spacesToShow == "visible" then "1" else "0";

    # The standard plist generator cannot represent the NSData used by
    # ShortcutRecorder. Import only the two shortcut preferences separately.
    home.activation.configureAltTabShortcut = lib.mkIf (cfg.shortcut != null) (
      lib.hm.dag.entryAfter [ "setDarwinDefaults" ] ''
        run /usr/bin/defaults import com.lwouis.alt-tab-macos ${shortcutPlist}
      ''
    );
  };
}

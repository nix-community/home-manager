{ config, lib, pkgs, ... }:
let
  inherit (builtins) baseNameOf listToAttrs map unsafeDiscardStringContext;
  inherit (lib) literalExpression mkEnableOption mkIf mkOption types;

  cfg = config.xdg.autostart;

  /* "/nix/store/x-foo/application.desktop" -> {
       name = "autostart/application.desktop";
       value = { source = "/nix/store/x-foo/application.desktop"; };
     }
  */
  mapDesktopEntry = entry: {
    name = "autostart/${unsafeDiscardStringContext (baseNameOf entry)}";
    value.source = entry;
  };

  linkedDesktopEntries = pkgs.runCommandNoCCLocal "xdg-autostart-entries" { } ''
    mkdir -p $out
    ${lib.concatMapStringsSep "\n" (e: "ln -s ${e} $out") cfg.entries}
  '';

in {
  meta.maintainers = with lib.maintainers; [ Scrumplex ];

  options.xdg.autostart = {
    enable = mkEnableOption "creation of XDG autostart entries";

    readOnly = mkOption {
      type = lib.types.bool;
      description = ''
        Make `XDG_CONFIG_HOME/autostart` a symlink to a readonly directory so that
        programs cannot install arbitrary autostart services.
      '';
      default = false;
      example = true;
    };

    entries = mkOption {
      type = with types; listOf path;
      description = ''
        Paths to desktop files that should be linked to `XDG_CONFIG_HOME/autostart`
      '';
      default = [ ];
      example = literalExpression ''
        [
          "''${pkgs.evolution}/share/applications/org.gnome.Evolution.desktop"
        ]
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.entries != [ ]) {
    xdg.configFile = if cfg.readOnly then {
      autostart.source = linkedDesktopEntries;
    } else
      listToAttrs (map mapDesktopEntry cfg.entries);
  };
}

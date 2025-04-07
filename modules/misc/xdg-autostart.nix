{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins)
    baseNameOf
    listToAttrs
    map
    unsafeDiscardStringContext
    ;
  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.xdg.autostart;

  linkedDesktopEntries = pkgs.runCommandNoCCLocal "xdg-autostart-entries" { } ''
    mkdir -p $out
    ${lib.concatMapStringsSep "\n" (e: "ln -s ${e} $out") cfg.entries}
  '';

in
{
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
    xdg.configFile.autostart = {
      source = linkedDesktopEntries;
      recursive = !cfg.readOnly;
    };
  };
}

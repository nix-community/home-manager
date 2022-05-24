{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.nushell;

  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ maintainers.Philipp-M ];

  imports = [
    (mkRenamedOptionModule [ "programs" "nushell" "settings" ] [
      "programs"
      "nushell"
      "legacySettings"
    ])
  ];

  options.programs.nushell = {
    enable = mkEnableOption "nushell";

    package = mkOption {
      type = types.package;
      default = pkgs.nushell;
      defaultText = literalExpression "pkgs.nushell";
      description = "The package to use for nushell.";
    };

    config = mkOption {
      type = types.lines;
      default = "";
      defaultText = literalExpression ''""'';
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/nushell/config.nu</filename>.
      '';
    };

    env = mkOption {
      type = types.lines;
      default = "";
      defaultText = literalExpression ''""'';
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/nushell/env.nu</filename>.
      '';
    };

    legacySettings = mkOption {
      type = with types;
        let
          prim = oneOf [ bool int str ];
          primOrPrimAttrs = either prim (attrsOf prim);
          entry = either prim (listOf primOrPrimAttrs);
          entryOrAttrsOf = t: either entry (attrsOf t);
          entries = entryOrAttrsOf (entryOrAttrsOf entry);
        in attrsOf entries // { description = "Nushell configuration"; };
      default = { };
      example = literalExpression ''
        {
          edit_mode = "vi";
          startup = [ "alias la [] { ls -a }" "alias e [msg] { echo $msg }" ];
          key_timeout = 10;
          completion_mode = "circular";
          no_auto_pivot = true;
        }
      '';
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/nu/config.toml</filename>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "nu/config.toml" = mkIf (cfg.legacySettings != { }) {
        source = tomlFormat.generate "nushell-config" cfg.settings;
      };
      "nushell/config.nu".text = mkIf (cfg.config == "") cfg.config;
      "nushell/env.nu".text = mkIf (cfg.env == "") cfg.env;
    };
  };
}

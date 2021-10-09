{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.nushell;

  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ maintainers.Philipp-M ];

  options.programs.nushell = {
    enable = mkEnableOption "nushell";

    package = mkOption {
      type = types.package;
      default = pkgs.nushell;
      defaultText = literalExpression "pkgs.nushell";
      description = "The package to use for nushell.";
    };

    settings = mkOption {
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
        <filename>~/.config/nushell/config.toml</filename>.
        </para><para>
        See <link xlink:href="https://www.nushell.sh/book/configuration.html" /> for the full list
        of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."nu/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "nushell-config" cfg.settings;
    };
  };
}

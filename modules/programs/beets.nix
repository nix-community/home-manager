{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.beets;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.beets = {
      enable = mkOption {
        type = types.bool;
        default = if versionAtLeast config.home.stateVersion "19.03" then
          false
        else
          cfg.settings != { };
        defaultText = "false";
        description = ''
          Whether to enable the beets music library manager. This
          defaults to <literal>false</literal> for state
          version ≥ 19.03. For earlier versions beets is enabled if
          <option>programs.beets.settings</option> is non-empty.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.beets;
        defaultText = literalExample "pkgs.beets";
        example =
          literalExample "(pkgs.beets.override { enableCheck = true; })";
        description = ''
          The <literal>beets</literal> package to use.
          Can be used to specify extensions.
        '';
      };

      settings = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Configuration written to
          <filename>~/.config/beets/config.yaml</filename>
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."beets/config.yaml".text =
      builtins.toJSON config.programs.beets.settings;
  };
}

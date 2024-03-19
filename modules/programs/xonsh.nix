{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.xonsh;

  linesOrSource = types.submodule ({ config, ... }: {
    options = {
      text = mkOption {
        type = types.lines;
        default =
          if config.source != null then builtins.readFile config.source else "";
        defaultText = literalExpression
          "if source is defined, the content of source, otherwise empty";
        description = ''
          Text of the xonshrc file.
          If unset then the source option will be preferred.
        '';
      };

      source = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path of the xonshrc file to use.
          If the text option is set, it will be preferred.
        '';
      };
    };
  });
in {
  meta.maintainers = [ hm.maintainers.inmaldrerah ];

  options.programs.xonsh = {
    enable = mkEnableOption "xonsh";

    package = mkOption {
      type = types.package;
      default = pkgs.xonsh;
      defaultText = literalExpression "pkgs.xonsh";
      description = "The package to use for xonsh.";
    };

    rcFiles = mkOption {
      type = types.attrsOf linesOrSource;
      default = { };
      example = literalExpression ''
        {
          "example.xsh".text = \'\'
            # Some code here
          \'\';
        }
      '';
      description = ''
        The run control file to be used for xonsh.

        See <https://xon.sh/xonshrc.html> for more information.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional configuration to add as a standalone xonshrc file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = mkMerge [
      (listToAttrs (map (set: {
        name = "xonsh/rc.d/" + set.name;
        value.text = set.value.text;
      }) (filter (set: set.value.text != "")
        (attrsets.attrsToList cfg.rcFiles))))
      (mkIf (cfg.extraConfig != "") {
        "xonsh/rc.d/user-extra.xsh".text = cfg.extraConfig;
      })
    ];
  };
}

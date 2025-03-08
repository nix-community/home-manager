{ config, lib, pkgs, ... }:
let yaml = pkgs.formats.yaml { };
in with lib; {
  meta.maintainers = with maintainers; [ arunoruto ];

  options.programs.vivid = {
    enable = mkEnableOption ''
      vivid - A themeable LS_COLORS generator with a rich filetype database
      <link xlink:href="https://github.com/sharkdp/vivid" />
    '';

    package = mkPackageOption pkgs "vivid" { };

    theme = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "molokai";
      description = ''
        Color theme to enable.
        Run `vivid themes` for a list of available themes.
      '';
    };

    filetypes = mkOption {
      type = yaml.type;
      default = { };
      example = literalExpression ''
        {
          core = {
            regular_file = [ "$fi" ];
            directory = [ "$di" ];
          };
          text = {
            readme = [ "README.md" ];
            licenses = [ "LICENSE" ];
          };
        }
      '';
      description = ''
        Configuration written to
        <filename>~/.config/vivid/filetypes.yml</filename>.
        Visit <link xlink:href="https://github.com/sharkdp/vivid/tree/master/config/filetypes.yml" />
        for a reference file.
      '';
    };

    themes = mkOption {
      type = types.attrsOf (yaml.type);
      default = { };
      example = literalExpression ''
        {
          mytheme = {
            colors = {
              blue = "0000ff";
            };
            core = {
              directory = {
                foreground = "blue";
                font-style = "bold";
              };
            };
          };
        }
      '';
      description = ''
        Theme files written to
        <filename>~/.config/vivid/themes/<mytheme>.yml</filename>.
        Visit <link xlink:href="https://github.com/sharkdp/vivid/tree/master/themes" />
        for references.
      '';
    };
  };

  config = let
    cfg = config.programs.vivid;
    lsColors = builtins.readFile (pkgs.runCommand "vivid-ls-colors" { } ''
      ${lib.getExe cfg.package} generate ${cfg.theme} > $out
    '');
  in mkIf cfg.enable {
    home = {
      packages = [ cfg.package ];
      sessionVariables = { LS_COLORS = "${lsColors}"; };
    };

    xdg.configFile = {
      "vivid/filetypes.yml" =
        mkIf (builtins.length (builtins.attrNames cfg.filetypes) > 0) {
          source = yaml.generate "filetypes.yml" cfg.filetypes;
        };
    } // mapAttrs' (name: value:
      nameValuePair "vivid/themes/${name}.yml" {
        source = yaml.generate "${name}.yml" value;
      }) cfg.themes;
  };
}

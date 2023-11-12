{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.pubs;

in {
  meta.maintainers = [ hm.maintainers.loicreynier ];

  options.programs.pubs = {
    enable = mkEnableOption "pubs";

    package = mkOption {
      type = types.package;
      default = pkgs.pubs;
      defaultText = literalExpression "pkgs.pubs";
      description = "The package to use for the pubs script.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = literalExpression ''
        '''
        [main]
        pubsdir = ''${config.home.homeDirectory}/.pubs
        docsdir = ''${config.home.homeDirectory}/.pubs/doc
        doc_add = link
        open_cmd = xdg-open

        [plugins]
        active = git,alias

        [[alias]]

        [[[la]]]
        command = list -a
        description = lists papers in lexicographic order

        [[git]]
        quiet = True
        manual = False
        force_color = False
        ''''';
      description = ''
        Configuration using syntax written to
        {file}`$HOME/.pubsrc`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".pubsrc" =
      mkIf (cfg.extraConfig != "") { text = cfg.extraConfig; };
  };
}

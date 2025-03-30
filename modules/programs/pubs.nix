{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types;

  cfg = config.programs.pubs;

in {
  meta.maintainers = [ lib.hm.maintainers.loicreynier ];

  options.programs.pubs = {
    enable = lib.mkEnableOption "pubs";

    package = lib.mkPackageOption pkgs "pubs" { };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = lib.literalExpression ''
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

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".pubsrc" =
      lib.mkIf (cfg.extraConfig != "") { text = cfg.extraConfig; };
  };
}

{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types;

  cfg = config.programs.zathura;

  formatLine = n: v:
    let
      formatValue = v:
        if lib.isBool v then (if v then "true" else "false") else toString v;
    in ''set ${n}	"${formatValue v}"'';

  formatMapLine = n: v: "map ${n}   ${toString v}";

in {
  meta.maintainers = [ lib.maintainers.rprospero ];

  options.programs.zathura = {
    enable = lib.mkEnableOption ''
      Zathura, a highly customizable and functional document viewer
      focused on keyboard interaction'';

    package = mkOption {
      type = types.package;
      default = pkgs.zathura;
      defaultText = "pkgs.zathura";
      description = "The Zathura package to use";
    };

    options = mkOption {
      default = { };
      type = with types; attrsOf (oneOf [ str bool int float ]);
      description = ''
        Add {option}`:set` command options to zathura and make
        them permanent. See
        {manpage}`zathurarc(5)`
        for the full list of options.
      '';
      example = {
        default-bg = "#000000";
        default-fg = "#FFFFFF";
      };
    };

    mappings = mkOption {
      default = { };
      type = with types; attrsOf str;
      description = ''
        Add {option}`:map` mappings to zathura and make
        them permanent. See
        {manpage}`zathurarc(5)`
        for the full list of possible mappings.

        You can create a mode-specific mapping by specifying the mode before the key:
        `"[normal] <C-b>" = "scroll left";`
      '';
      example = {
        D = "toggle_page_mode";
        "<Right>" = "navigate next";
        "[fullscreen] <C-i>" = "zoom in";
      };
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional commands for zathura that will be added to the
        {file}`zathurarc` file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."zathura/zathurarc".text = lib.concatStringsSep "\n" ([ ]
      ++ lib.optional (cfg.extraConfig != "") cfg.extraConfig
      ++ lib.mapAttrsToList formatLine cfg.options
      ++ lib.mapAttrsToList formatMapLine cfg.mappings) + "\n";
  };
}

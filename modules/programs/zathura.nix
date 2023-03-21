{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zathura;

  formatLine = n: v:
    let
      formatValue = v:
        if isBool v then (if v then "true" else "false") else toString v;
    in ''set ${n}	"${formatValue v}"'';

  formatMapLine = n: v: "map ${n}   ${toString v}";

in {
  meta.maintainers = [ maintainers.rprospero ];

  options.programs.zathura = {
    enable = mkEnableOption ''
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
      type = with types; attrsOf (either str (either bool int));
      description = ''
        Add <option>:set</option> command options to zathura and make
        them permanent. See
        <citerefentry>
          <refentrytitle>zathurarc</refentrytitle>
          <manvolnum>5</manvolnum>
        </citerefentry>
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
        Add <option>:map</option> mappings to zathura and make
        them permanent. See
        <citerefentry>
          <refentrytitle>zathurarc</refentrytitle>
          <manvolnum>5</manvolnum>
        </citerefentry>
        for the full list of possible mappings.

        You can create a mode-specific mapping by specifying the mode before the key:
        <literal>"[normal] &lt;C-b&gt;" = "scroll left";</literal>
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
        <filename>zathurarc</filename> file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."zathura/zathurarc".text = concatStringsSep "\n" ([ ]
      ++ optional (cfg.extraConfig != "") cfg.extraConfig
      ++ mapAttrsToList formatLine cfg.options
      ++ mapAttrsToList formatMapLine cfg.mappings) + "\n";
  };
}

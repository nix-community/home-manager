{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.i3blocks;

  mapAttrsToList = f: attrs: map (name: f name attrs.${name}) (attrNames attrs);

  formatSet = s:
    let formatArg = name: value: "${name}=${toString value}";
    in mapAttrsToList formatArg s;
  formatBlocks = blocks:
    let
      formatBlock = block:
        [''

          [${block.name or ""}]'']
        ++ (formatSet (removeAttrs block [ "name" ]));
    in builtins.concatLists (map formatBlock blocks);

in {
  meta.maintainers = [ hm.maintainers.vawvaw ];

  options.programs.i3blocks = {
    enable = mkEnableOption "i3blocks";

    globalVars = mkOption {
      type = with types; attrsOf (oneOf [ str number ]);
      default = { };
      description = ''
        Variables to set globally at the beginning of the
        <filename>config</filename> file.
        See <link xlink:href="https://github.com/vivien/i3blocks#blocks" />
      '';
      example = literalExpression ''
        SCRIPT_DIR = "$HOME/i3blocks";
      '';
    };

    blocks = mkOption {
      type = types.listOf (with types; attrsOf (oneOf [ str number ]));
      default = [ ];
      description = ''
        Blocks to add to i3blocks <filename>config</filename> file. See
        <link xlink:href="https://github.com/vivien/i3blocks#i3blocks-properties" />
        for options.
      '';
      example = literalExpression ''
        [
          {
            name = "time";
            command = "date '+%d.%m.%4Y %T'";
            interval = 5;
          }
        ]
      '';
    };

    package = mkPackageOption pkgs "i3blocks" { };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."i3blocks/config".text = (concatStringsSep "\n"
      ((formatSet cfg.globalVars) ++ (formatBlocks cfg.blocks))) + "\n";
  };
}

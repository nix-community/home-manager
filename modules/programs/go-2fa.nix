{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.go-2fa;
in {
  meta.maintainers = [ maintainers.mlvzk ];

  options = {
    programs.go-2fa = {
      enable = mkEnableOption "go-2fa";

      codes = mkOption {
        default = { };
        example = {
          discord = "qwer tyui opas dfgh";
          twitter = {
            code = "qwer tyui opas dfgh";
            length = 6;
          };
        };
        type = types.attrsOf (types.oneOf [ types.str types.attrs ]);
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.go-2fa ];

    home.file.".2fa".text = let
      genLineAttr = k: v:
        "${k} ${if v ? length then builtins.toString v.length else "6"} ${
          strings.replaceChars [ " " ] [ "" ] v.code
        }";
      genLine = k: v:
        if builtins.isString v then
          genLineAttr k { code = v; }
        else
          genLineAttr k v;
    in concatStringsSep "\n" (mapAttrsToList genLine cfg.codes);
  };
}

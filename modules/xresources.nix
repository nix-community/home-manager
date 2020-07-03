{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xresources;

  formatLine = n: v:
    let
      formatList = x:
        if isList x then
          throw "can not convert 2-dimensional lists to Xresources format"
        else
          formatValue x;

      formatValue = v:
        if isBool v then
          (if v then "true" else "false")
        else if isList v then
          concatMapStringsSep ", " formatList v
        else
          toString v;
    in "${n}: ${formatValue v}";

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    xresources.properties = mkOption {
      type = with types;
        let
          prim = either bool (either int str);
          entry = either prim (listOf prim);
        in nullOr (attrsOf entry);
      default = null;
      example = literalExample ''
        {
          "Emacs*toolBar" = 0;
          "XTerm*faceName" = "dejavu sans mono";
          "XTerm*charClass" = [ "37:48" "45-47:48" "58:48" "64:48" "126:48" ];
        }
      '';
      description = ''
        X server resources that should be set.
        Booleans are formatted as "true" or "false" respectively.
        List elements are recursively formatted as a string and joined by commas.
        All other values are directly formatted using builtins.toString. 
        Note, that 2-dimensional lists are not supported and specifying one will throw an exception.
        If this and all other xresources options are
        <code>null</code>, then this feature is disabled and no
        <filename>~/.Xresources</filename> link is produced.
      '';
    };

    xresources.extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = literalExample ''
        builtins.readFile (
            pkgs.fetchFromGitHub {
                owner = "solarized";
                repo = "xresources";
                rev = "025ceddbddf55f2eb4ab40b05889148aab9699fc";
                sha256 = "0lxv37gmh38y9d3l8nbnsm1mskcv10g3i83j0kac0a2qmypv1k9f";
            } + "/Xresources.dark"
        )
      '';
      description = ''
        Additional X server resources contents.
        If this and all other xresources options are
        <code>null</code>, then this feature is disabled and no
        <filename>~/.Xresources</filename> link is produced.
      '';
    };
  };

  config = mkIf ((cfg.properties != null && cfg.properties != { })
    || cfg.extraConfig != "") {
      home.file.".Xresources" = {
        text = concatStringsSep "\n" ([ ]
          ++ optional (cfg.extraConfig != "") cfg.extraConfig
          ++ optionals (cfg.properties != null)
          (mapAttrsToList formatLine cfg.properties)) + "\n";
        onChange = ''
          if [[ -v DISPLAY ]] ; then
            $DRY_RUN_CMD ${pkgs.xorg.xrdb}/bin/xrdb -merge $HOME/.Xresources
          fi
        '';
      };
    };
}

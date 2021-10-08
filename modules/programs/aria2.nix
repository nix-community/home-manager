{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.aria2;

  formatLine = n: v:
    let
      formatValue = v:
        if builtins.isBool v then
          (if v then "true" else "false")
        else
          toString v;
    in "${n}=${formatValue v}";
in {
  meta.maintainers = [ hm.maintainers.justinlovinger ];

  options.programs.aria2 = {
    enable = mkEnableOption "aria2";

    settings = mkOption {
      type = with types; attrsOf (oneOf [ bool float int str ]);
      default = { };
      description = ''
        Options to add to <filename>aria2.conf</filename> file.
        See
        <citerefentry>
          <refentrytitle>aria2c</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>
        for options.
      '';
      example = literalExpression ''
        {
          listen-port = 60000;
          dht-listen-port = 60000;
          seed-ratio = 1.0;
          max-upload-limit = "50K";
          ftp-pasv = true;
        }
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra lines added to <filename>aria2.conf</filename> file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.aria2 ];

    xdg.configFile."aria2/aria2.conf".text = concatStringsSep "\n" ([ ]
      ++ mapAttrsToList formatLine cfg.settings
      ++ optional (cfg.extraConfig != "") cfg.extraConfig);
  };
}

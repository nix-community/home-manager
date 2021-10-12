{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.noti;

in {
  meta.maintainers = [ maintainers.marsam ];

  options.programs.noti = {
    enable = mkEnableOption "Noti";

    settings = mkOption {
      type = types.attrsOf (types.attrsOf types.str);
      default = { };
      description = ''
        Configuration written to
        <filename>~/.config/noti/noti.yaml</filename>.
        </para><para>
        See
        <citerefentry>
          <refentrytitle>noti.yaml</refentrytitle>
          <manvolnum>5</manvolnum>
        </citerefentry>.
        for the full list of options.
      '';
      example = literalExpression ''
        {
          say = {
            voice = "Alex";
          };
          slack = {
            token = "1234567890abcdefg";
            channel = "@jaime";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.noti ];

    xdg.configFile."noti/noti.yaml" =
      mkIf (cfg.settings != { }) { text = generators.toYAML { } cfg.settings; };
  };

}

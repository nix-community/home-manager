{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.aerc;
  formatIni = pkgs.formats.ini { };

  toStylesetConfig = generators.toKeyValue {
    mkKeyValue = k: v:
      let value = (if isBool v then boolToString else toString) v;
      in "${k} = ${value}";
  };

  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support"
  else
    config.xdg.configHome;
in {
  options = {
    programs.aerc = {
      enable = mkEnableOption "aerc, an email client for your terminal.";

      binds = mkOption {
        type = formatIni.type;
        default = { };
        defaultText = literalExpression "{ }";
        example = literalExpression ''
          "messages:account=Mailbox" = {
            c = ":cf path:mailbox/** and<space>";
          };
        '';
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/aerc/binds.conf</filename>. See
          <link xlink:href="https://git.sr.ht/~rjarry/aerc/tree/master/item/doc/aerc-config.5.scd"/>
          for the documentation.
        '';
      };

      conf = mkOption {
        type = formatIni.type;
        default = { };
        defaultText = literalExpression "{ }";
        example = literalExpression ''
          ui = {
            index-format = "%-20.20D %-17.17n %Z %s";
            timestamp-format = "2006-01-02 03:04 PM";
          };
        '';
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/aerc/aerc.conf</filename>. See
          <link xlink:href="https://git.sr.ht/~rjarry/aerc/tree/master/item/doc/aerc-config.5.scd"/>
          for the documentation.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.aerc;
        defaultText = literalExpression "pkgs.aerc";
        description = "The <command>aerc</command> package to install.";
      };

      styleset = mkOption {
        type = types.attrs;
        default = { };
        defaultText = literalExpression "{ }";
        example = literalExpression ''
          {
            "*.selected.fg" = "aqua";
            "*.selected.bg" = "magenta";
          };
        '';
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/aerc/stylesets/default</filename>. See
          <link xlink:href="https://git.sr.ht/~rjarry/aerc/tree/master/item/doc/aerc-stylesets.7.scd"/>
          for the documentation.
        '';
      };

      templates = mkOption {
        type = types.attrsOf types.str;
        default = { };
        defaultText = literalExpression "{ }";
        example = literalExpression ''
          {
            "forward_as_body" = '''
              X-Mailer: aerc {{version}}

              Forwarded message from {{(index .OriginalFrom 0).Name}} on {{dateFormat .OriginalDate "Mon Jan 2, 2006 at 3:04 PM"}}:
              {{.OriginalText}}
            ''';
          };
        '';
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/aerc/stylesets/default</filename>. See
          <link xlink:href="https://git.sr.ht/~rjarry/aerc/tree/master/item/doc/aerc-stylesets.7.scd"/>
          for the documentation.
        '';
      };

      queryMaps = mkOption {
        type = types.listOf types.str;
        default = [ ];
        defaultText = literalExpression "[ ]";
        example = literalExpression ''
          [
            "inbox=tag:inbox and not tag:archived"
            "github=tag:github"
          ];
        '';
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/aerc/querymaps.conf</filename>. See
          <link xlink:href="https://git.sr.ht/~rjarry/aerc/tree/master/item/doc/aerc-notmuch.5.scd"/>
          for the documentation.
        '';
      };
    };

    config = mkIf cfg.enable {
      meta.maintainers = [ maintainers.ratsclub ];

      home.packages = [ cfg.package ];

      home.file = {
        "${configDir}/aerc/aerc.conf" = mkIf (cfg.conf != { }) {
          source = formatIni.generate "aerc.conf" cfg.conf;
        };

        "${configDir}/aerc/binds.conf" = mkIf (cfg.binds != { }) {
          source = formatIni.generate "binds.conf" cfg.binds;
        };

        "${configDir}/aerc/stylesets/default" = mkIf (cfg.styleset != { }) {
          source = pkgs.writeText "default" (toStylesetConfig cfg.styleset);
        };

        "${configDir}/aerc/querymaps.conf" = mkIf (cfg.queryMaps != [ ]) {
          source = pkgs.writeText "querymaps.conf"
            (strings.concatStringsSep "\n" cfg.queryMaps);
        };
      } // attrsets.mapAttrs' (name: value:
        nameValuePair ("${configDir}/aerc/templates/${name}") ({
          text = value;
        })) cfg.templates;
    };
  };
}

{ config, options, lib, pkgs, ... }:

with lib;

# TODO: Fix the formatting of the resulting config.
let
  cfg = config.services.recoll;

  # The key-value generator for Recoll config format. For future references,
  # see the example configuration from the package (i.e.,
  # `$out/share/recoll/examples/recoll.conf`).
  mkRecollConfKeyValue = generators.mkKeyValueDefault {
    mkValueString = let mkQuoted = v: ''"${escape [ ''"'' ] v}"'';
    in v:
    if v == true then
      "1"
    else if v == false then
      "0"
    else if isList v then
      concatMapStringsSep " " mkQuoted v
    else
      generators.mkValueStringDefault { } v;
  } " = ";

  # A modified version of 'lib.generators.toINI' that also accepts top-level
  # attributes as non-attrsets.
  toRecollConf = { listsAsDuplicateKeys ? false }:
    attr:
    let
      toKeyValue = generators.toKeyValue {
        inherit listsAsDuplicateKeys;
        mkKeyValue = mkRecollConfKeyValue;
      };
      mkSectionName = name: strings.escape [ "[" "]" ] name;
      convert = k: v:
        if isAttrs v then
          ''
            [${mkSectionName k}]
          '' + toKeyValue v
        else
          toKeyValue { "${k}" = v; };

      # TODO: Improve this chunk of code, pls.
      # There's a possibility of attributes with attrsets overriding other
      # top-level attributes with non-attrsets so we're forcing the attrsets to
      # come last.
      _config = mapAttrsToList convert (filterAttrs (k: v: !isAttrs v) attr);
      _config' = mapAttrsToList convert (filterAttrs (k: v: isAttrs v) attr);
      config = _config ++ _config';
    in concatStringsSep "\n" config;

  # A specific type for Recoll config format. Taken from `pkgs.formats`
  # implementation from nixpkgs. See the 'Nix-representable formats' from the
  # NixOS manual for more information.
  recollConfFormat = { }: {
    type = with types;
      let
        valueType = nullOr (oneOf [
          bool
          float
          int
          path
          str
          (attrsOf valueType)
          (listOf valueType)
        ]) // {
          description = "Recoll config value";
        };
      in attrsOf valueType;

    generate = name: value: pkgs.writeText name (toRecollConf { } value);
  };

  # The actual object we're going to use for this module. This is for the sake
  # of consistency (and dogfooding the settings format implementation).
  settingsFormat = recollConfFormat { };
in {
  meta.maintainers = [ maintainers.foo-dogsquared ];

  options.services.recoll = {
    enable = mkEnableOption "Recoll file index service";

    package = mkOption {
      type = types.package;
      default = pkgs.recoll;
      defaultText = literalExpression "pkgs.recoll";
      description = ''
        Package providing the <literal>recoll</literal> binary.
      '';
      example = literalExpression "(pkgs.recoll.override { withGui = false; })";
    };

    startAt = mkOption {
      type = types.str;
      default = "hourly";
      example = "00/2:00";
      description = ''
        When or how often the periodic update should run. Must be the format
        described from
        <citerefentry>
          <refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum>
        </citerefentry>.
      '';
    };

    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        The configuration to be written at
        <filename>''${config.services.recoll.configDir}/recoll.conf</filename>.

        See
        <citerefentry>
          <refentrytitle>recoll</refentrytitle>
          <manvolnum>5</manvolnum>
        </citerefentry> for more details about the configuration.
      '';
      example = literalExpression ''
        {
          nocjk = true;
          loglevel = 5;
          topdirs = [ "~/Downloads" "~/Documents" "~/projects" ];

          "~/Downloads" = {
            "skippedNames+" = [ "*.iso" ];
          };

          "~/projects" = {
            "skippedNames+" = [ "node_modules" "target" "result" ];
          };
        }
      '';
    };

    configDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.recoll";
      defaultText = literalExpression "\${config.home.homeDirectory}/.recoll";
      example = literalExpression "\${config.xdg.configHome}/recoll";
      description = ''
        The directory to contain Recoll configuration files. This will be set
        as <literal>RECOLL_CONFDIR</literal>.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.recoll" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    home.sessionVariables = { RECOLL_CONFDIR = cfg.configDir; };

    home.file."${cfg.configDir}/recoll.conf".source =
      settingsFormat.generate "recoll-conf-${config.home.username}"
      cfg.settings;

    systemd.user.services.recollindex = {
      Unit = {
        Description = "Recoll index update";
        Documentation = [
          "man:recoll"
          "man:recollindex"
          "https://www.lesbonscomptes.com/recoll/usermanual/"
        ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/recollindex";
        Environment = [ "RECOLL_CONFDIR=${escapeShellArg cfg.configDir}" ];
      };
    };

    systemd.user.timers.recollindex = {
      Unit = {
        Description = "Recoll index update";
        PartOf = [ "default.target" ];
      };

      Timer = {
        Persistent = true;
        OnCalendar = cfg.startAt;
      };

      Install.WantedBy = [ "timers.target" ];
    };
  };
}

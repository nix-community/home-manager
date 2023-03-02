{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zellij;

  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support/org.Zellij-Contributors.Zellij"
  else
    "${config.xdg.configHome}/zellij";

  # Generate a KDL-style config file from an attrset of nodes
  # To learn more about the KDL format, see
  # https://github.com/kdl-org/kdl/blob/main/SPEC.md
  toKdl = attrs:
    let
      mapAttrsToStringsSep = sep: mapFn: attrs:
        concatStringsSep sep (mapAttrsToList mapFn attrs);

      mapListToStringsSep = sep: mapFn: list:
        concatStringsSep sep (map mapFn list);

      processValue = value:
        if (isInt value) then
          toString value
        else if (isFloat value) then
          floatToString value
        else if (isString value) then
          ''"${value}"''
        else if (value == true) then
          "true"
        else if (value == false) then
          "false"
        else if (value == null) then
          "null"
        else if (isList value) then
          (mapListToStringsSep " " processValue value)
        else
          "";

      processProps =
        mapAttrsToStringsSep "" (key: value: "${key}=${processValue value}");

      processNode = name: value:
        if isAttrs value then
          let
            args = optionalString (hasAttr "__args" value)
              (processValue value.__args);

            props = optionalString (hasAttr "__props" value)
              (processProps value.__props);

            childrenAttrs = filterAttrs
              (name: value: (name != "__args") || (name != "__props")) value;

            children = optionalString (childrenAttrs != { }) ''
              {
              ${processAttrsOfNodes childrenAttrs}
              }'';

          in concatStringsSep " " [ name args props children ";" ]
        else
          "${name} ${processValue value};";

      processAttrsOfNodes = mapAttrsToStringsSep "\n" processNode;

      # map input to ini sections
    in processAttrsOfNodes attrs;

in {
  meta.maintainers = [ hm.maintainers.mainrs ];

  options.programs.zellij = {
    enable = mkEnableOption "zellij";

    package = mkOption {
      type = types.package;
      default = pkgs.zellij;
      defaultText = literalExpression "pkgs.zellij";
      description = ''
        The zellij package to install.
      '';
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      example = literalExpression ''
        {
          theme = "custom";
          themes.custom.fg = 5;
        }
      '';
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/zellij/config.kdl</filename>.
        </para><para>
        See <link xlink:href="https://zellij.dev/documentation" /> for the full
        list of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."${configDir}/config.kdl" =
      mkIf (cfg.settings != { }) { text = toKdl cfg.settings; };
  };
}

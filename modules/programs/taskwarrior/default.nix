{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.programs.taskwarrior;

  formatValue =
    value:
    if lib.isBool value then
      if value then "true" else "false"
    else if lib.isList value then
      lib.concatMapStringsSep "," formatValue value
    else
      toString value;

  formatLine = key: value: "${key}=${formatValue value}";

  formatSet =
    key: values:
    (lib.concatStringsSep "\n" (
      lib.mapAttrsToList (subKey: subValue: formatPair "${key}.${subKey}" subValue) values
    ));

  formatPair = key: value: if lib.isAttrs value then formatSet key value else formatLine key value;
in
{
  options = {
    programs.taskwarrior = {
      enable = lib.mkEnableOption "Task Warrior";

      config = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        example = lib.literalExpression ''
          {
            confirmation = false;
            report.minimal.filter = "status:pending";
            report.active.columns = [ "id" "start" "entry.age" "priority" "project" "due" "description" ];
            report.active.labels  = [ "ID" "Started" "Age" "Priority" "Project" "Due" "Description" ];
            taskd = {
              certificate = "/path/to/cert";
              key = "/path/to/key";
              ca = "/path/to/ca";
              server = "host.domain:53589";
              credentials = "Org/First Last/cf31f287-ee9e-43a8-843e-e8bbd5de4294";
            };
          }
        '';
        description = ''
          Key-value configuration written to
          {file}`$XDG_CONFIG_HOME/task/taskrc`.
        '';
      };

      dataLocation = mkOption {
        type = types.str;
        default = "${config.xdg.dataHome}/task";
        defaultText = "$XDG_DATA_HOME/task";
        description = ''
          Location where Task Warrior will store its data.

          Home Manager will attempt to create this directory.
        '';
      };

      colorTheme = mkOption {
        type = with types; nullOr (either str path);
        default = null;
        example = "dark-blue-256";
        description = ''
          Either one of the default provided theme as string, or a
          path to a theme configuration file.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional content written at the end of
          {file}`$XDG_CONFIG_HOME/task/taskrc`.
        '';
      };

      package = lib.mkPackageOption pkgs "taskwarrior" {
        nullable = true;
        example = "pkgs.taskwarrior3";
      };
    };
  };

  config =
    let
      homeConf = "${config.xdg.configHome}/task/home-manager-taskrc";
      userConf = "${config.xdg.configHome}/task/taskrc";
    in
    lib.mkIf cfg.enable {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      home.file."${homeConf}".text = ''
        data.location=${cfg.dataLocation}
        ${lib.optionalString (cfg.colorTheme != null) (
          if lib.isString cfg.colorTheme then
            "include ${cfg.colorTheme}.theme"
          else
            "include ${cfg.colorTheme}"
        )}

        ${lib.concatStringsSep "\n" (lib.mapAttrsToList formatPair cfg.config)}

        ${cfg.extraConfig}
      '';

      home.activation.regenDotTaskRc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        verboseEcho "Ensuring generated taskwarrior config included in taskrc"

        if [[ ! -s "${userConf}" ]]; then
          # Ensure file's existence
          if [[ -v DRY_RUN ]]; then
            run echo "include ${homeConf}" ">" "${userConf}"
          else
            echo "include ${homeConf}" > "${userConf}"
          fi
        elif ! grep -qF "include ${homeConf}" ${lib.escapeShellArg userConf}; then
          # Add include statement for Home Manager generated config.
          run sed -i '1i include ${homeConf}' ${lib.escapeShellArg userConf}
        fi
      '';
    };
}

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.taskwarrior;

  formatValue = value:
    if isBool value then
      if value then "true" else "false"
    else if isList value then
      concatMapStringsSep "," formatValue value
    else
      toString value;

  formatLine = key: value: "${key}=${formatValue value}";

  formatSet = key: values:
    (concatStringsSep "\n"
      (mapAttrsToList (subKey: subValue: formatPair "${key}.${subKey}" subValue)
        values));

  formatPair = key: value:
    if isAttrs value then formatSet key value else formatLine key value;

  homeConf = "${config.xdg.configHome}/task/home-manager-taskrc";
  userConf = "${config.xdg.configHome}/task/taskrc";
in {
  options = {
    programs.taskwarrior = {
      enable = mkEnableOption "Task Warrior";

      config = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        example = literalExpression ''
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

      package =
        mkPackageOption pkgs "taskwarrior" { example = "pkgs.taskwarrior3"; };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."${homeConf}".text = ''
      data.location=${cfg.dataLocation}
      ${optionalString (cfg.colorTheme != null) (if isString cfg.colorTheme then
        "include ${cfg.colorTheme}.theme"
      else
        "include ${cfg.colorTheme}")}

      ${concatStringsSep "\n" (mapAttrsToList formatPair cfg.config)}

      ${cfg.extraConfig}
    '';

    home.activation.regenDotTaskRc = hm.dag.entryAfter [ "writeBoundary" ] ''
      verboseEcho "Ensuring generated taskwarrior config included in taskrc"

      if [[ ! -s "${userConf}" ]]; then
        # Ensure file's existence
        if [[ -v DRY_RUN ]]; then
          run echo "include ${homeConf}" ">" "${userConf}"
        else
          echo "include ${homeConf}" > "${userConf}"
        fi
      elif ! grep -qF "include ${homeConf}" ${escapeShellArg userConf}; then
        # Add include statement for Home Manager generated config.
        run sed -i '1i include ${homeConf}' ${escapeShellArg userConf}
      fi
    '';
  };
}

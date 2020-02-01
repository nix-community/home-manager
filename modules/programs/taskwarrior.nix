{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.taskwarrior;

  themePath = theme: "${pkgs.taskwarrior}/share/doc/task/rc/${theme}.theme";

  includeTheme = location:
    if location == null then
      ""
    else if isString location then
      "include ${themePath location}"
    else
      "include ${location}";

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

in {
  options = {
    programs.taskwarrior = {
      enable = mkEnableOption "Task Warrior";

      config = mkOption {
        type = types.attrs;
        default = { };
        example = literalExample ''
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
          <filename>~/.taskrc</filename>.
        '';
      };

      dataLocation = mkOption {
        type = types.str;
        default = "${config.xdg.dataHome}/task";
        defaultText = "$XDG_DATA_HOME/task";
        description = ''
          Location where Task Warrior will store its data.
          </para><para>
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
          <filename>~/.taskrc</filename>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.taskwarrior ];

    home.file."${cfg.dataLocation}/.keep".text = "";

    home.file.".taskrc".text = ''
      data.location=${cfg.dataLocation}
      ${includeTheme cfg.colorTheme}

      ${concatStringsSep "\n" (mapAttrsToList formatPair cfg.config)}

      ${cfg.extraConfig}
    '';
  };
}

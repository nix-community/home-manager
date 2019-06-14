{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.calcurse;

  formatLine = n: v:
    let
      formatValue = v:
        if isBool v then (if v then "yes" else "no")
        else toString v;
    in
      "${lib.toLower n}=${formatValue v}";

in

{
  meta.maintainers = [ maintainers.arian-d ];
  options.programs.calcurse = {
    enable = mkEnableOption "calcurse";

    general = {
      autoSave = mkOption {
        type = types.bool;
        default = true;
        description = ''
          This option allows to automatically save the user’s data (if set to
          yes) when quitting. warning: No data will be automatically saved if
          general.autosave is set to no. This means the user must press S (for
          saving) in order to retrieve its modifications.
        '';
      };

      autogc = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Automatically run the garbage collector for note files when quitting.
        '';
      };

      periodicSave = mkOption {
        type = types.int;
        default = 0;
        description = ''
          If different from 0, user’s data will be automatically saved every
          general.periodicsave minutes. When an automatic save is performed,
          two asterisks (i.e. **) will appear on the top right-hand side of
          the screen).'';
      };

      confirmQuit = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If set to yes, confirmation is required before quitting, otherwise
          pressing Q will cause calcurse to quit without prompting for user
          confirmation.
        '';
      };

      confirmDelete = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If this option is set to yes, pressing D for deleting an item (either
          a todo, appointment, or event), will lead to a prompt asking for user
          confirmation before removing the selected item from the list.
          Otherwise, no confirmation will be needed before deleting the item.
        '';
      };

      systemDialogs = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Setting this option to no will result in skipping the system dialogs
          related to the saving and loading of data. This can be useful to
          speed up the input/output processes.
        '';
      };

      progressBar = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If set to no, this will cause the disappearing of the progress bar
          which is usually shown when saving data to file. If set to yes, this
          bar will be displayed, together with the name of the file being saved
        '';
      };

      firstDayOfWeek = mkOption {
        type = types.str;
        default = "monday";
        description = ''
          One can choose between Monday and Sunday as the first day of the week.
          If general.firstdayofweek is set to monday, Monday will be first in
          the calendar view. Otherwise, Sunday will be the first day of the week
        '';
      };
    };

    appearance = {
      compactPanels = mkOption {
        type = types.bool;
        default = false;
        description = ''
          In compact panels mode, all captions are removed from panels.
        '';
      };

      defaultPanel = mkOption {
        type = types.str;
        default = "calendar";
        description = ''
          This can be used to specify the panel to be selected on startup
        '';
      };

      calendarView = mkOption {
        type = types.str;
        default = "monthly";
        description = ''
          If set to 0, the monthly calendar view will be displayed by default
          otherwise it is the weekly view that will be displayed.
        '';
      };

      layout = mkOption {
        type = types.int;
        default = 0;
        description = ''
          Eight different layouts are to be chosen from (see layout
          configuration screen for the description of the available layouts).
        '';
      };

      sidebarWidth = mkOption {
        type = types.int;
        default = 0;
        description = ''
          Width (in percentage, 0 being the minimum width) of the side bar.
        '';
      };

      notifyBar = mkOption {
        type = types.bool;
        default = true;
        description = ''
          This option indicates if you want the notify-bar to be displayed or
          not.
        '';
      };
    };

    notification = {
      warning = mkOption {
        type = types.int;
        default = 300;
        description = ''
          When there is an appointment which is flagged as important within the
          next notification.warning seconds, the display of that appointment
          inside the notify-bar starts to blink. Moreover, the command defined
          by the notification.command option will be launched. That way, the
          user is warned and knows there will be soon an upcoming appointment.
        '';
      };

      command = mkOption {
        type = types.str;
        default = "printf '\\a'";
        description = ''
          This option indicates which command is to be launched when there is
          an upcoming appointment flagged as important. This command will be
          passed to the user’s shell which will interpret it. To know what shell
          must be used, the content of the $SHELL environment variable is used.
          If this variable is not set, /bin/sh is used instead.
        '';
      };

      notifyAll = mkOption {
        type = types.str;
        default = "flagged-only";
        description = ''
          If set to flagged-only, you are only notified of flagged items. If
          set to unflagged-only, you are only notified of unflagged items.
          If set to all, notifications are always sent, independent of whether
          an item is flagged or not. For historical reasons, this option also
          accepts boolean values where yes equals flagged-only and no equals
          unflagged-only.
        '';
      };
    };

    extraConfig = mkOption {
      type = types.str;
      default = "";
      description = "These lines are appended to the calcurse configuration.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.calcurse ];

    home.file.".calcurse/conf".text = concatStringsSep "\n" (
      map (g: "general." + g) (mapAttrsToList formatLine cfg.general)
      ++ map (a: "appearance." + a) (mapAttrsToList formatLine cfg.appearance)
      ++ map (n: "notification." + n) (mapAttrsToList formatLine cfg.notification)
      ) + "\n";
  };
}

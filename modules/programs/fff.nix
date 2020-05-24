{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.fff;

in {
  meta.maintainers = [ maintainers.gigahawk ];

  options.programs.fff = {
    enable = mkEnableOption "A simple file manager written in bash";

    cdOnExit = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Change directory to current folder on exit
        '';
      };

      name = mkOption {
        type = types.str;
        default = "f";
        description = ''
          Name of function used to call fff.
        '';
      };

      commands = mkOption {
        type = types.str;
        default = ''
          # cd to exited folder for bash and zsh
          fff "$@"
          cd "$(cat "''${XDG_CACHE_HOME:=''${HOME}/.cache}/fff/.fff_d")" 
        '';
        example = "";
        description = ''
          Bash/Zsh commands used to start fff with cdOnExit enabled.
        '';
      };

      fishCommands = mkOption {
        type = types.str;
        default = ''
          fff $argv
          cd (cat ${cfg.cdOnExit.helperFile})
        '';
        description = ''
          Fish commands used to start fff with cdOnExit enabled.
        '';
      };

      helperFile = mkOption {
        type = types.str;
        default = "${config.xdg.cacheHome}/fff/.fff_d";
        description = ''
          Location of CD on exit helper file
        '';
      };
    };

    settings = {
      lsColors = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Use LS_COLORS to color fff
        '';
      };
      color = {
        "1" = mkOption {
          type = types.ints.between 0 9;
          default = 2;
          description = ''
            Directory color [0-9]
          '';
        };
        "2" = mkOption {
          type = types.ints.between 0 9;
          default = 7;
          description = ''
            Status color [0-9]
          '';
        };
        "3" = mkOption {
          type = types.ints.between 0 9;
          default = 6;
          description = ''
            Selection color [0-9] (copied/moved files)
          '';
        };
        "4" = mkOption {
          type = types.ints.between 0 9;
          default = 1;
          description = ''
            Cursor color [0-9]
          '';
        };
      };
      fileOpener = mkOption {
        type = types.str;
        default = "xdg-open";
        description = ''
          File opener
        '';
      };
      trash = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/.local/share/fff/trash";
        description = ''
          Path to trash directory
        '';
      };
      trashCmd = mkOption {
        type = types.str;
        default = "mv";
        description = ''
          Command to use when trashing a file
        '';
      };
      favorites = {
        "1" = mkOption {
          type = types.str;
          default = "";
          description = ''
            Bookmark/favorite path (dir/file), key 1 to navigate here.
          '';
        };
        "2" = mkOption {
          type = types.str;
          default = "";
          description = ''
            Bookmark/favorite path (dir/file), key 2 to navigate here.
          '';
        };
        "3" = mkOption {
          type = types.str;
          default = "";
          description = ''
            Bookmark/favorite path (dir/file), key 3 to navigate here.
          '';
        };
        "4" = mkOption {
          type = types.str;
          default = "";
          description = ''
            Bookmark/favorite path (dir/file), key 4 to navigate here.
          '';
        };
        "5" = mkOption {
          type = types.str;
          default = "";
          description = ''
            Bookmark/favorite path (dir/file), key 5 to navigate here.
          '';
        };
        "6" = mkOption {
          type = types.str;
          default = "";
          description = ''
            Bookmark/favorite path (dir/file), key 6 to navigate here.
          '';
        };
        "7" = mkOption {
          type = types.str;
          default = "";
          description = ''
            Bookmark/favorite path (dir/file), key 7 to navigate here.
          '';
        };
        "8" = mkOption {
          type = types.str;
          default = "";
          description = ''
            Bookmark/favorite path (dir/file), key 8 to navigate here.
          '';
        };
        "9" = mkOption {
          type = types.str;
          default = "";
          description = ''
            Bookmark/favorite path (dir/file), key 9 to navigate here.
          '';
        };
      };
      w3mXOffset = mkOption {
        type = types.int;
        default = 0;
        description = ''
          w3m-img x offset.
        '';
      };
      w3mYOffset = mkOption {
        type = types.int;
        default = 0;
        description = ''
          w3m-img x offset.
        '';
      };
      fileFormat = mkOption {
        type = types.str;
        default = "%f";
        example = "	%f";
        description = ''
          Format of a file string ("%f" is the current file).
        '';
      };
      markFormat = mkOption {
        type = types.str;
        default = " %f*";
        example = "> %f";
        description = ''
          Format of a marked item string ("%f" is the current file).
        '';
      };
    };

    keyBindings = {
      child1 = mkOption {
        type = types.str;
        default = "l";
        description = ''
          1st key to enter child directory
        '';
      };
      child2 = mkOption {
        type = types.str;
        default = "$(echo $'\\e[C')"; # Workaround for sessionVariables
        description = ''
          2nd key to enter child directory (Default is right arrow)
        '';
      };
      child3 = mkOption {
        type = types.str;
        default = "";
        description = ''
          3nd key to enter child directory (Default is enter/return)
        '';
      };

      parent1 = mkOption {
        type = types.str;
        default = "h";
        description = ''
          1st key to enter parent directory
        '';
      };
      parent2 = mkOption {
        type = types.str;
        default = "$(echo $'\\e[D')"; # Workaround for sessionVariables
        description = ''
          2nd key to enter parent directory (Default is left arrow).
        '';
      };
      parent3 = mkOption {
        type = types.str;
        default = "$(echo $'\\177')"; # Workaround for sessionVariables
        description = ''
          3nd key to enter parent directory (Default is backspace).
        '';
      };
      parent4 = mkOption {
        type = types.str;
        default = "$(echo $'\\b')"; # Workaround for sessionVariables
        description = ''
          3nd key to enter parent directory 
          (Default is backspace for older termainals).
        '';
      };

      previous = mkOption {
        type = types.str;
        default = "-";
        description = ''
          Key to go to previous directory.
        '';
      };

      search = mkOption {
        type = types.str;
        default = "/";
        description = ''
          Key to search.
        '';
      };

      shell = mkOption {
        type = types.str;
        default = "!";
        description = ''
          Key to spawn a shell.
        '';
      };

      down1 = mkOption {
        type = types.str;
        default = "j";
        description = ''
          1st key to move cursor down.
        '';
      };
      down2 = mkOption {
        type = types.str;
        default = "$(echo $'\\e[B')"; # Workaround for sessionVariables
        description = ''
          2nd key to move cursor down (Default is down arrow).
        '';
      };

      up1 = mkOption {
        type = types.str;
        default = "k";
        description = ''
          1st key to move cursor up.
        '';
      };
      up2 = mkOption {
        type = types.str;
        default = "$(echo $'\\e[A')"; # Workaround for sessionVariables
        description = ''
          2nd key to move cursor up (Default is up arrow).
        '';
      };

      top = mkOption {
        type = types.str;
        default = "g";
        description = ''
          Key to move cursor to top.
        '';
      };
      bottom = mkOption {
        type = types.str;
        default = "G";
        description = ''
          Key to move cursor to bottom.
        '';
      };

      goDir = mkOption {
        type = types.str;
        default = ":";
        description = ''
          Key to go to a directory.
        '';
      };
      goHome = mkOption {
        type = types.str;
        default = "~";
        description = ''
          Key to go to home directory.
        '';
      };
      goTrash = mkOption {
        type = types.str;
        default = "t";
        description = ''
          Key to go to trash directory.
        '';
      };

      yank = mkOption {
        type = types.str;
        default = "y";
        description = ''
          Key to select a file for yanking.
        '';
      };
      move = mkOption {
        type = types.str;
        default = "m";
        description = ''
          Key to select a file for moving.
        '';
      };
      trash = mkOption {
        type = types.str;
        default = "d";
        description = ''
          Key to select a file for trashing.
        '';
      };
      link = mkOption {
        type = types.str;
        default = "s";
        description = ''
          Key to select a file for linking.
        '';
      };
      bulkRename = mkOption {
        type = types.str;
        default = "b";
        description = ''
          Key to select a file for bulk renaming.
        '';
      };

      yankAll = mkOption {
        type = types.str;
        default = "Y";
        description = ''
          Key to select all files for yanking.
        '';
      };
      moveAll = mkOption {
        type = types.str;
        default = "M";
        description = ''
          Key to select all files for moving.
        '';
      };
      trashAll = mkOption {
        type = types.str;
        default = "D";
        description = ''
          Key to select all files for trashing.
        '';
      };
      linkAll = mkOption {
        type = types.str;
        default = "S";
        description = ''
          Key to select all files for linking.
        '';
      };
      bulkRenameAll = mkOption {
        type = types.str;
        default = "B";
        description = ''
          Key to select all files for bulk renaming.
        '';
      };

      commit = mkOption {
        type = types.str;
        default = "p";
        description = ''
          Key to commit action (yank, move, etc.) on selected files.
        '';
      };
      clear = mkOption {
        type = types.str;
        default = "c";
        description = ''
          Key to clear all selected files.
        '';
      };

      rename = mkOption {
        type = types.str;
        default = "r";
        description = ''
          Key to rename a file.
        '';
      };
      mkdir = mkOption {
        type = types.str;
        default = "n";
        description = ''
          Key to create a directory.
        '';
      };
      mkfile = mkOption {
        type = types.str;
        default = "f";
        description = ''
          Key to create a file.
        '';
      };

      attributes = mkOption {
        type = types.str;
        default = "x";
        description = ''
          Key to show file attributes.
        '';
      };

      hidden = mkOption {
        type = types.str;
        default = ".";
        description = ''
          Key to toggle hidden files.
        '';
      };
    };
  };

  config = let
    cdOnExitStr = if cfg.cdOnExit.enable then
      config.lib.shell.function cfg.cdOnExit.name cfg.cdOnExit.commands
    else
      "";
    fffVariables = {
      FFF_LS_COLORS = if cfg.settings.lsColors then 1 else 0;
      FFF_COL1 = cfg.settings.color."1";
      FFF_COL2 = cfg.settings.color."2";
      FFF_COL3 = cfg.settings.color."3";
      FFF_COL4 = cfg.settings.color."4";
      FFF_OPENER = cfg.settings.fileOpener;
      FFF_CD_ON_EXIT = if cfg.cdOnExit.enable then 1 else 0;
      FFF_CD_FILE = cfg.cdOnExit.helperFile;
      FFF_TRASH = cfg.settings.trash;
      FFF_TRASH_CMD = cfg.settings.trashCmd;

      FFF_FAV1 = cfg.settings.favorite."1";
      FFF_FAV2 = cfg.settings.favorite."2";
      FFF_FAV3 = cfg.settings.favorite."3";
      FFF_FAV4 = cfg.settings.favorite."4";
      FFF_FAV5 = cfg.settings.favorite."5";
      FFF_FAV6 = cfg.settings.favorite."6";
      FFF_FAV7 = cfg.settings.favorite."7";
      FFF_FAV8 = cfg.settings.favorite."8";
      FFF_FAV9 = cfg.settings.favorite."9";

      FFF_W3M_XOFFSET = cfg.settings.w3mXOffset;
      FFF_W3M_YOFFSET = cfg.settings.w3mYOffset;

      FFF_FILE_FORMAT = cfg.settings.fileFormat;
      FFF_MARK_FORMAT = cfg.settings.markFormat;

      FFF_KEY_CHILD1 = cfg.keyBindings.child1;
      FFF_KEY_CHILD2 = cfg.keyBindings.child2;
      FFF_KEY_CHILD3 = cfg.keyBindings.child3;

      FFF_KEY_PARENT1 = cfg.keyBindings.parent1;
      FFF_KEY_PARENT2 = cfg.keyBindings.parent2;
      FFF_KEY_PARENT3 = cfg.keyBindings.parent3;
      FFF_KEY_PARENT4 = cfg.keyBindings.parent4;

      FFF_KEY_PREVIOUS = cfg.keyBindings.previous;

      FFF_KEY_SEARCH = cfg.keyBindings.search;

      FFF_KEY_SHELL = cfg.keyBindings.shell;

      FFF_KEY_SCROLL_DOWN1 = cfg.keyBindings.down1;
      FFF_KEY_SCROLL_DOWN2 = cfg.keyBindings.down2;

      FFF_KEY_SCROLL_UP1 = cfg.keyBindings.up1;
      FFF_KEY_SCROLL_UP2 = cfg.keyBindings.up2;

      FFF_KEY_TO_TOP = cfg.keyBindings.top;
      FFF_KEY_TO_BOTTOM = cfg.keyBindings.bottom;

      FFF_KEY_GO_DIR = cfg.keyBindings.goDir;
      FFF_KEY_GO_HOME = cfg.keyBindings.goHome;
      FFF_KEY_GO_TRASH = cfg.keyBindings.goTrash;

      FFF_KEY_YANK = cfg.keyBindings.yank;
      FFF_KEY_MOVE = cfg.keyBindings.move;
      FFF_KEY_TRASH = cfg.keyBindings.trash;
      FFF_KEY_LINK = cfg.keyBindings.link;
      FFF_KEY_BULK_RENAME = cfg.keyBindings.bulkRename;

      FFF_KEY_YANK_ALL = cfg.keyBindings.yankAll;
      FFF_KEY_MOVE_ALL = cfg.keyBindings.moveAll;
      FFF_KEY_TRASH_ALL = cfg.keyBindings.trashAll;
      FFF_KEY_LINK_ALL = cfg.keyBindings.linkAll;
      FFF_KEY_BULK_RENAME_ALL = cfg.keyBindings.bulkRenameAll;

      FFF_KEY_PASTE = cfg.keyBindings.commit;
      FFF_KEY_CLEAR = cfg.keyBindings.clear;

      FFF_KEY_RENAME = cfg.keyBindings.rename;
      FFF_KEY_MKDIR = cfg.keyBindings.mkdir;
      FFF_KEY_MKFILE = cfg.keyBindings.mkfile;

      FFF_KEY_ATTRIBUTES = cfg.keyBindings.attributes;

      FFF_KEY_HIDDEN = cfg.keyBindings.hidden;
    };
    cdOnExitFunc = ''
      ${cfg.cdOnExit.name}() {
        ${cfg.cdOnExit.commands}
      }
    '';
    cdOnExitFishFunc = ''
      function ${cfg.cdOnExit.name}
        ${cfg.cdOnExit.fishCommands}
      end
    '';

  in mkIf cfg.enable {
    home.packages = [ pkgs.fff ];

    programs.bash.initExtra = mkIf cfg.cdOnExit.enable cdOnExitFunc;
    programs.zsh.initExtra = mkIf cfg.cdOnExit.enable cdOnExitFunc;
    programs.fish.interactiveShellInit = mkIf cfg.cdOnExit.enable cdOnExitFishFunc;
  };
}

lib:
let
  mkActivatableOption = description:
    lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
      inherit description;
    };
  mkDeactivatableOption = description:
    lib.mkOption {
      default = true;
      example = false;
      type = lib.types.bool;
      inherit description;
    };
in {
  autoindent = mkDeactivatableOption ''
    When creating a new line,
      use the same indentation as the previous line.
  '';
  autosave = lib.mkOption {
    type = lib.types.int;
    default = 0;
    example = 60;
    description = ''
      Automatically save the buffer every n seconds,
        where n is the value of the autosave option.
      Also when quitting on a modified buffer,
        micro will automatically save and quit.
      Be warned:
        This option saves the buffer without prompting the user,
          so data may be overwritten.
      If this option is set to 0,
        no autosaving is performed.
    '';
  };
  autosu = mkActivatableOption ''
    When a file is saved that the user does not have permission to modify,
      micro will ask if the user would like to use super user privileges to save the file.
    If this option is enabled,
      micro will automatically attempt to use super user privileges to save without asking the user.
  '';
  backup = mkDeactivatableOption ''
    micro will automatically keep backups of all open buffers.
    Backups are stored in ~/.config/micro/backups and are removed when the buffer is closed cleanly.
    In the case of a system crash or a micro crash,
      the contents of the buffer can be recovered automatically by opening the file that was being edited before the crash
      or manually by searching for the backup in the backup directory.
    Backups are made in the background for newly modified buffers every 8 seconds or when micro detects a crash.
  '';
  backupdir = lib.mkOption {
    type = lib.types.str;
    default = "";
    example = ".backups/micro";
    description = ''
      The directory micro should place backups in.
      For the default value of "" (empty string),
        the backup directory will be ConfigDir/backups,
          which is ~/.config/micro/backups by default.
      The directory specified for backups will be created if it does not exist.
    '';
  };
  basename = mkActivatableOption ''
    In the infobar and tabbar,
     show only the basename of the file being edited rather than the full path.
  '';
  clipboard = lib.mkOption {
    type = lib.types.enum [ "external" "terminal" "internal" ];
    default = "external";
    example = "internal";
    description = ''
      Specifies how micro should access the system clipboard. Possible values are:
      external:
        Accesses clipboard via an external tool,
          such as xclip/xsel or wl-clipboard on Linux,
          pbcopy/pbpaste on MacOS,
          and system calls on Windows.
        On Linux,
          if you do not have one of the tools installed or if they are not working,
        micro will throw an error and use an internal clipboard.
      terminal:
        Accesses the clipboard via your terminal emulator.
        Note that there is limited support among terminal emulators for this feature (called OSC 52).
        Terminals that are known to work are
          Kitty (enable reading with clipboard_control setting),
          iTerm2 (only copying),
          st,
          rxvt-unicode and
          xterm if enabled (see > help copypaste for details).
        Note that Gnome-terminal does not support this feature.
        With this setting,
          copy-paste will work over ssh.
        See > help copypaste for details.
      internal:
        micro will use an internal clipboard.
    '';
  };
  colorcolumn = lib.mkOption {
    type = lib.types.int;
    default = 0;
    example = 80;
    description = ''
      If this is not set to 0,
        it will display a column at the specified column.
      This is useful if you want column 80 to be highlighted special for example.
    '';
  };
  colorscheme = lib.mkOption {
    type = lib.types.str;
    default = "default";
    example = "solarized";
    description = ''
      Loads the colorscheme stored in $(configDir)/colorschemes/option.micro.
      Note that the default colorschemes (default, solarized, and solarized-tc) are not located in configDir,
        because they are embedded in the micro binary.
      The colorscheme can be selected from all the files in the ~/.config/micro/colorschemes/ directory.
      You can read more about micro’s colorschemes in the colors help topic (help colors).
    '';
  };
  cursorline = mkDeactivatableOption ''
    Highlight the line that the cursor is on in a different color (the color is defined by the colorscheme you are using).
  '';
  diffgutter = mkActivatableOption ''
    Display diff indicators before lines.
  '';
  divchars = lib.mkOption {
    type = lib.types.str;
    default = "|-";
    example = "‖–";
    description = ''
      Specifies the “divider” characters used for the dividing line between vertical/horizontal splits.
      The first character is for vertical dividers and the second is for horizontal dividers.
      By default,
        for horizontal splits the statusline serves as a divider,
      but if the statusline is disabled the horizontal divider character will be used.
    '';
  };
  divreverse = mkDeactivatableOption ''
    Colorschemes provide the color (foreground and background) for the characters displayed in split dividers.
    With this option enabled,
      the colors specified by the colorscheme will be reversed (foreground and background colors swapped).
  '';
  encoding = lib.mkOption {
    type = lib.types.str;
    default = "utf-8";
    example = "latin1";
    description = ''
      The encoding to open and save files with.
      Supported encodings are listed at https://www.w3.org/TR/encoding/.
    '';
  };
  eofnewline = mkDeactivatableOption ''
    micro will automatically add a newline to the end of the file if one does not exist.
  '';
  fastdirty = mkActivatableOption ''
    This determines what kind of algorithm micro uses to determine if a buffer is modified or not.
    When fastdirty is on,
      micro just uses a boolean modified that is set to true as soon as the user makes an edit.
    This is fast,
      but can be inaccurate.
    If fastdirty is off,
      then micro will hash the current buffer against a hash of the original file (created when the buffer was loaded).
    This is more accurate but obviously more resource intensive.
    This option will be automatically disabled if the file size exceeds 50KB.
  '';
  fileformat = lib.mkOption {
    type = lib.types.enum [ "unix" "dos" ];
    default = "unix";
    example = "dos";
    description = ''
      This determines what kind of line endings micro will use for the file.
      Unix line endings are just \n (linefeed) whereas dos line endings are \r\n (carriage return + linefeed).
      The two possible values for this option are "unix" and "dos".
      The fileformat will be automatically detected (when you open an existing file) and displayed on the statusline,
        but this option is useful if you would like to change the line endings or if you are starting a new file.
      Changing this option while editing a file will change its line endings.
      Opening a file with this option set will only have an effect if the file is empty/newly created,
        because otherwise the fileformat will be automatically detected from the existing line endings.
    '';
  };
  filetype = lib.mkOption {
    type = lib.types.str;
    default = "unknown";
    example = "unknown";
    description = ''
      Sets the filetype for the current buffer.
      Set this option to off to completely disable filetype detection.
      This will be automatically overridden depending on the file you open.
    '';
  };
  ignorecase = mkActivatableOption ''
    Perform case-insensitive searches.
  '';
  indentchar = lib.mkOption {
    type = lib.types.str;
    default = " ";
    example = "→";
    description = ''
      Sets the indentation character.
    '';
  };
  infobar = mkDeactivatableOption ''
    Enables the line at the bottom of the editor where messages are printed.
  '';
  keepautoindent = mkActivatableOption ''
    When using autoindent, whitespace is added for you.
    This option determines
      if when you move to the next line without any insertions
        the whitespace that was added should be deleted to remove trailing whitespace.
    By default, the autoindent whitespace is deleted if the line was left empty.
  '';
  keymenu = mkActivatableOption ''
    Display the nano-style key menu at the bottom of the screen.
    Note that ToggleKeyMenu is bound to Alt-g by default and this is displayed in the statusline.
    To disable this, simply rebind Alt-g to UnbindKey.
  '';
  matchbrace = mkDeactivatableOption ''
    Underline matching braces for '()', '{}', '[]' when the cursor is on a brace character.
  '';
  mkparents = mkActivatableOption ''
    If a file is opened on a path that does not exist,
      the file cannot be saved because the parent directories do not exist.
    This option lets micro automatically create the parent directories in such a situation.
  '';
  mouse = mkDeactivatableOption ''
    Enable mouse support.
    When mouse support is disabled,
      usually the terminal will be able to access mouse events,
      which can be useful if you want to copy from the terminal instead of from micro.
    E.g. for ssh, because the terminal has access to the local clipboard and micro does not.
  '';
  paste = mkActivatableOption ''
    Treat characters sent from the terminal in a single chunk as a paste event
      rather than a series of manual key presses.
    If you are pasting using the terminal keybinding (not Ctrl-v, which is micro's default paste keybinding),
      then it is a good idea to
        enable this option during the paste and
        disable once the paste is over.
    See > help copypaste for details about copying and pasting in a terminal environment.
  '';
  parsecursor = mkActivatableOption ''
    If enabled,
      this will cause micro to parse filenames such as file.txt:10:5 as
        requesting to open file.txt with the cursor at line 10 and column 5.
    The column number can also be dropped to open the file at a given line and column 0.
    Note that with this option enabled it is not possible to open a file such as file.txt:10:5,
      where :10:5 is part of the filename.
    It is also possible to open a file with a certain cursor location by using the +LINE,COL flag syntax.
    See micro -help for the command line options.
  '';
  permbackup = mkActivatableOption ''
    This option causes backups (see backup option) to be permanently saved.
    With permanent backups,
      micro will not remove backups when files are closed and will never apply them to existing files.
    Use this option if you are interested in manually managing your backup files.
  '';
  pluginchannels = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      "https://raw.githubusercontent.com/micro-editor/plugin-channel/master/channel.json"
    ];
    example = [ ];
    description = ''
      List of URLs pointing to plugin channels for downloading and installing plugins.
      A plugin channel consists of a json file with links to plugin repos,
        which store information about plugin versions and download URLs.
    '';
  };
  pluginrepos = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ ];
    description = ''
      A list of links to plugin repositories.
    '';
  };
  readonly = mkActivatableOption ''
    When enabled,
      disallows edits to the buffer.
    It is recommended to only ever set this option locally using setlocal.
  '';
  rmtrailingws = mkActivatableOption ''
    micro will automatically trim trailing whitespaces at ends of lines.
  '';
  ruler = mkDeactivatableOption ''
    Display line numbers.
  '';
  relativeruler = mkActivatableOption ''
    Make line numbers display relatively.
    If set to true,
      all lines except for the line that the cursor is located will display the distance from the cursor’s line.
  '';
  savecursor = mkActivatableOption ''
    Remember where the cursor was last time the file was opened and put it there when you open the file again.
    Information is saved to ~/.config/micro/buffers/.
  '';
  savehistory = mkDeactivatableOption ''
    Remember command history between closing and re-opening micro.
    Information is saved to ~/.config/micro/buffers/history.
  '';
  saveundo = mkActivatableOption ''
    When this option is on,
      undo is saved even after you close a file
    so if you close and reopen a file,
      you can keep undoing.
    Information is saved to ~/.config/micro/buffers/.
  '';
  scrollbar = mkActivatableOption ''
    Display a scroll bar.
  '';
  scrollmargin = lib.mkOption {
    type = lib.types.int;
    default = 3;
    example = 4;
    description = ''
      Margin at which the view starts scrolling when the cursor approaches the edge of the view.
    '';
  };
  scrollspeed = lib.mkOption {
    type = lib.types.int;
    default = 2;
    example = 4;
    description = ''
      Amount of lines to scroll for one scroll event.
    '';
  };
  smartpaste = mkDeactivatableOption ''
    Add leading whitespace when pasting multiple lines.
    This will attempt to preserve the current indentation level when pasting an unindented block.
  '';
  softwrap = mkActivatableOption ''
    Wrap lines that are too long to fit on the screen.
  '';
  splitbottom = mkDeactivatableOption ''
    When a horizontal split is created, create it below the current split.
  '';
  splitright = mkDeactivatableOption ''
    When a vertical split is created, create it to the right of the current split.
  '';
  statusformatl = lib.mkOption {
    type = lib.types.str;
    default =
      "$(filename) $(modified)($(line),$(col)) $(status.paste)| ft:$(opt:filetype) | $(opt:fileformat) | $(opt:encoding)";
    example =
      "$(filename) $(modified)($(line),$(col)) $(status.paste) ft:$(opt:filetype) $(opt:fileformat) $(opt:encoding";
    description = ''
      Format string definition for the left-justified part of the statusline.
      Special directives should be placed inside $().
      Special directives include:
        filename, modified, line, col, opt, bind.
      The opt and bind directives take either an option or an action afterward and
        fill in the value of the option or the key bound to the action.
    '';
  };
  statusformatr = lib.mkOption {
    type = lib.types.str;
    default = "$(bind:ToggleKeyMenu): bindings, $(bind:ToggleHelp): help";
    example = "";
    description = ''
      Format string definition for the right-justified part of the statusline.
    '';
  };
  statusline = mkDeactivatableOption ''
    Display the status line at the bottom of the screen.
  '';
  sucmd = lib.mkOption {
    type = lib.types.str;
    default = "sudo";
    example = "doas";
    description = ''
      Specifies the super user command.
      On most systems this is "sudo" but on BSD it can be "doas".
      This option can be customized and is only used when saving with su.
    '';
  };
  syntax = mkDeactivatableOption ''
    Enables syntax highlighting.
  '';
  tabmovement = mkActivatableOption ''
    Navigate spaces at the beginning of lines as if they are tabs (e.g. move over 4 spaces at once).
    This option only does anything if tabstospaces is on.
  '';
  tabsize = lib.mkOption {
    type = lib.types.int;
    default = 4;
    example = 2;
    description = ''
      The size in spaces that a tab character should be displayed with.
    '';
  };
  tabstospaces = mkActivatableOption ''
    Use spaces instead of tabs.
  '';
  useprimary = mkDeactivatableOption ''
    Only useful on unix:
      Defines whether or not micro will use the primary clipboard to copy selections in the background.
      This does not affect the normal clipboard using Ctrl-c and Ctrl-v.
  '';
  xterm = mkActivatableOption ''
    micro will assume that the terminal it is running in conforms to xterm-256color
      regardless of what the $TERM variable actually contains.
    Enabling this option may cause unwanted effects
      if your terminal in fact does not conform to the xterm-256color standard.
  '';
}

{ lib, options, ... }:

{
  programs.fzf = {
    enable = true;
    fileWidgetCommand = "fd --type f";
    fileWidgetOptions = [ "--preview 'head {}'" ];
    changeDirWidgetCommand = "fd --type d";
    changeDirWidgetOptions = [ "--preview 'tree -C {} | head -200'" ];
    historyWidgetCommand = "";
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
  };

  test.asserts.warnings.expected = [
    "The option `programs.fzf.historyWidgetCommand' defined in ${lib.showFiles options.programs.fzf.historyWidgetCommand.files} has been renamed to `programs.fzf.historyWidget.command'."
    "The option `programs.fzf.historyWidgetOptions' defined in ${lib.showFiles options.programs.fzf.historyWidgetOptions.files} has been renamed to `programs.fzf.historyWidget.options'."
    "The option `programs.fzf.changeDirWidgetOptions' defined in ${lib.showFiles options.programs.fzf.changeDirWidgetOptions.files} has been renamed to `programs.fzf.changeDirWidget.options'."
    "The option `programs.fzf.changeDirWidgetCommand' defined in ${lib.showFiles options.programs.fzf.changeDirWidgetCommand.files} has been renamed to `programs.fzf.changeDirWidget.command'."
    "The option `programs.fzf.fileWidgetOptions' defined in ${lib.showFiles options.programs.fzf.fileWidgetOptions.files} has been renamed to `programs.fzf.fileWidget.options'."
    "The option `programs.fzf.fileWidgetCommand' defined in ${lib.showFiles options.programs.fzf.fileWidgetCommand.files} has been renamed to `programs.fzf.fileWidget.command'."
  ];

  nmt.script = ''
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_CTRL_T_COMMAND="fd --type f"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_ALT_C_COMMAND="fd --type d"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_CTRL_R_OPTS="--sort --exact"'
  '';
}

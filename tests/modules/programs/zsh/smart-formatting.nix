{
  programs.zsh = {
    enable = true;
    # Add many setOptions to trigger multi-line formatting
    setOptions = [
      "AUTO_LIST"
      "AUTO_PARAM_SLASH"
      "AUTO_PUSHD"
      "ALWAYS_TO_END"
      "CORRECT"
      "HIST_FCNTL_LOCK"
      "HIST_VERIFY"
      "INTERACTIVE_COMMENTS"
      "MENU_COMPLETE"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_TO_HOME"
      "PUSHD_SILENT"
      "NOTIFY"
      "PROMPT_SUBST"
      "MULTIOS"
      "NOFLOWCONTROL"
      "NO_CORRECT_ALL"
      "NO_HIST_BEEP"
      "NO_NOMATCH"
    ];
    # This should also show intelligent formatting for history options
    history = {
      size = 50000;
      save = 50000;
      # These will create many disabled options
      append = false;
      ignoreDups = false;
      ignoreAllDups = false;
      saveNoDups = false;
      findNoDups = false;
      ignoreSpace = false;
      expireDuplicatesFirst = false;
      extended = false;
      share = false;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContent home-files/.zshrc ${./smart-formatting-expected.zshrc}
  '';
}

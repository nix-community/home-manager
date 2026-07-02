{
  programs.fzf = {
    enable = true;
    defaultCommand = "fd --type f";
    defaultOptions = [
      "--height 40%"
      "--border"
    ];
    fileWidget = {
      command = "fd --type f";
      options = [ "--preview 'head {}'" ];
    };
    changeDirWidget = {
      command = "fd --type d";
      options = [ "--preview 'tree -C {} | head -200'" ];
    };
    historyWidget.options = [
      "--sort"
      "--exact"
    ];
    colors = {
      bg = "#1e1e1e";
    };
    tmux = {
      enableShellIntegration = true;
      shellIntegrationOptions = [ "-d 40%" ];
    };
  };

  nmt.script = ''
    # Test default options
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_DEFAULT_COMMAND="fd --type f"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_DEFAULT_OPTS="--height 40% --border --color'

    # Test file widget
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_CTRL_T_COMMAND="fd --type f"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_CTRL_T_OPTS="--preview'

    # Test change dir widget
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_ALT_C_COMMAND="fd --type d"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_ALT_C_OPTS="--preview'

    # Test history widget
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_CTRL_R_OPTS="--sort --exact"'

    # Test tmux
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_TMUX="1"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_TMUX_OPTS="-d 40%"'

    # Test colors are exported
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'FZF_DEFAULT_OPTS=.*--color'
  '';
}

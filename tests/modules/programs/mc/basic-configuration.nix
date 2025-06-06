{
  programs.mc = {
    enable = true;

    extraConfig = ''
      [Midnight-Commander]
      skin=nicedark
      show_hidden=true
      auto_save_setup=true
    '';

    keymapConfig = ''
      [panel]
      Enter = Select
    '';
  };
}

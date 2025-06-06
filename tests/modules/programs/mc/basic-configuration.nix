{
  programs.mc = {
    enable = true;

    settings = {
      "Midnight-Commander" = {
         skin = "nicedark";
         show_hidden = true;
         auto_save_setup = true;
      };
    };

    keymapSettings = {
      panel = {
        Enter = "Select";
      };
    };
  };
}

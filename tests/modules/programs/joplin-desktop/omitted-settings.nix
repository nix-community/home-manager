{
  imports = [ ./no-settings.nix ];

  programs.joplin-desktop.settings = {
    editor = "";
    "sync.target" = null;
  };
}

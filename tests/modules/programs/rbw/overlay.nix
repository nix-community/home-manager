self: super: {
  rbw = self.writeScriptBin "dummy-rbw" "";
  pinentry = {
    gnome3 = self.writeScriptBin "pinentry-gnome3" "" // {
      outPath = "@pinentry-gnome3@";
    };
    gtk2 = self.writeScriptBin "pinentry-gtk2" "" // {
      outPath = "@pinentry-gtk2@";
    };
    flavors = [ "gnome3" "gtk2" ];
  };
}

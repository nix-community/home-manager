{ config, ... }:

{
  fonts.fontconfig.enable = true;

  fonts.fontconfig.configFile.tamzen-disable-antialiasing = {
    enable = true;
    text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig></fontconfig>
    '';
  };

  fonts.fontconfig.configFile.user-owned = {
    enable = true;
    target = "50-user.conf";
    text = "<fontconfig></fontconfig>";
  };

  assertions = [
    {
      assertion = !config.xdg.configFile."fontconfig/conf.d/50-user.conf".force;
      message = "Expected a custom fontconfig.configFile target not to be forced.";
    }
    {
      assertion = config.xdg.configFile."fontconfig/conf.d/10-hm-fonts.conf".force;
      message = ''
        Expected the generated fontconfig conf.d entries to be forcibly
        overwritten, since an external tool (e.g. KDE's fontinst) replacing
        the managed symlink with a plain-file copy would otherwise make
        activation fail on the next rebuild.
      '';
    }
    {
      assertion = config.xdg.configFile."fontconfig/conf.d/90-hm-tamzen-disable-antialiasing.conf".force;
      message = "Expected user-defined fontconfig.configFile entries with the default target to be forced too.";
    }
  ];
}

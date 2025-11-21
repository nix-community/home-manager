{ pkgs, ... }:

{
  config = {
    programs.imv = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-imv" "";
      settings = {
        options.background = "ffffff";
        aliases.x = "close";
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/imv/config
      assertFileContent home-files/.config/imv/config \
          ${./basic-configuration.conf}
    '';
  };
}

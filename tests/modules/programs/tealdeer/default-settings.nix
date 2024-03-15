{ config, pkgs, ... }: {
  config = {
    programs.tealdeer = {
      package = config.lib.test.mkStubPackage { name = "tldr"; };
      enable = true;
    };

    nmt.script = let
      expectedConfDir = if pkgs.stdenv.isDarwin then
        "Library/Application Support"
      else
        ".config";
      expectedConfigPath = "home-files/${expectedConfDir}/tealdeer/config.toml";
    in ''
      assertPathNotExists "${expectedConfigPath}"
    '';
  };
}

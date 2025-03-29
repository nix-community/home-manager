{ config, pkgs, ... }: {
  config = {
    programs.tex-fmt = {
      enable = true;
      settings = {
        wrap = true;
        tabsize = 2;
        tabchar = "space";
        lists = [ ];
      };
    };

    nmt.script = let
      expectedConfDir = if pkgs.stdenv.isDarwin then
        "Library/Application Support"
      else
        ".config";
      expectedConfigPath = "home-files/${expectedConfDir}/tex-fmt/tex-fmt.toml";
    in ''
      assertFileExists "${expectedConfigPath}"
      assertFileContent "${expectedConfigPath}" ${
        pkgs.writeText "tex-fmt.config-custom.expected" ''
          lists = []
          tabchar = "space"
          tabsize = 2
          wrap = true
        ''
      }
    '';
  };
}

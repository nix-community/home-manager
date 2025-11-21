{ config, pkgs, ... }:
{
  config = {
    programs.tex-fmt = {
      enable = true;
    };

    nmt.script =
      let
        expectedConfDir = if pkgs.stdenv.isDarwin then "Library/Application Support" else ".config";
        expectedConfigPath = "home-files/${expectedConfDir}/tex-fmt/tex-fmt.toml";
      in
      ''
        assertPathNotExists "${expectedConfigPath}"
      '';
  };
}

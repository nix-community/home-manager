{ config, pkgs, lib, xdg, ... }:

{
  config.programs.vim-vint = {
    enable = true;
    settings = {
      cmdargs = {
        severity = "error";
        color = true;
        env = { neovim = true; };
      };
      policies = {
        ProhibitEqualTildeOperator.enabled = false;
        ProhibitUsingUndeclaredVariable.enabled = false;
        ProhibitAbbreviationOption.enabled = false;
        ProhibitImplicitScopeVariable.enabled = false;
        ProhibitSetNoCompatible.enabled = false;
      };
    };
    config.nmt.script = let configFile = xdg.configFile.".vintrc.yaml";
    in "	  assertFileContent \\\n	  \"${configFile}\" \\\n	  ${
         ./basic-configuration.yaml
       }\n  ";
  };
}

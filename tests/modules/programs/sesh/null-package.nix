{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./basic-configuration.nix ];

  programs.sesh.package = lib.mkForce null;

  assertions = [
    {
      assertion = !(lib.elem pkgs.sesh config.home.packages);
      message = "sesh should not be installed when package is null";
    }
    {
      assertion = config.home.shellAliases.s == "sesh connect $(sesh list --icons | fzf --ansi)";
      message = "the sesh alias should remain available when package is null";
    }
    {
      assertion = lib.hasInfix "sesh connect" config.programs.tmux.extraConfig;
      message = "the sesh Tmux integration should remain available when package is null";
    }
  ];
}

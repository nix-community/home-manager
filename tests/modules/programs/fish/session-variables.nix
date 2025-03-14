{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.sessionVariables = {
      V1 = "v1";
      V2 = "v2-${config.home.sessionVariables.V1}";
    };

    programs.fish = {
      enable = true;

      # TODO: should there be an equivalent sessionVariables here like bash + zsh?
    };

    nmt.script = ''
      assertFileExists home-path/etc/profile.d/hm-session-vars.fish
      assertFileRegex home-path/etc/profile.d/hm-session-vars.fish \
        "set -gx V1 'v1'"
      assertFileRegex home-path/etc/profile.d/hm-session-vars.fish \
        "set -gx V1 'v1'"
    '';
  };
}

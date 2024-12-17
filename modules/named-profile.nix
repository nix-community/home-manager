{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.named-profile;

  name = cfg.suffix;
  dot_suffix = if name != "" then ".${name}" else "";
  dash_suffix = if name != "" then "-${name}" else "";
  dash_suffix_ = if name != "" then "-${name}_" else "-";
  upper_suffix = lib.toUpper "${name}_";

in {
  options = {
    named-profile.suffix = lib.mkOption {
      default = "";
      description = ''
        The profile suffix name. Set to `""` to use the default file names
        otherwise they will be suffixed with this value.

        Files (like .bashrc, .bash_profile, ...) are suffix with `.$suffix`.
        Directories are siffuxed with `-$suffix`.
      '';
      type = types.str;
    };
  };

  config = mkIf (name != "") {
    programs.bash.bashProfileFile = ".bash_profile${dot_suffix}";
    programs.bash.bashrcFile = ".bashrc${dot_suffix}";
    programs.bash.profileFile = ".profile${dot_suffix}";
    programs.bash.bashLogoutFile = ".bash_logout${dot_suffix}";

    home.profileDirectory = mkOverride defaultOverridePriority
      (if config.submoduleSupport.enable
      && config.submoduleSupport.externalPackageInstall then
        "/etc/profiles/per-user/${cfg.username}${dash_suffix}"
      else if config.nix.enable
      && (config.nix.settings.use-xdg-base-directories or false) then
        "${config.xdg.stateHome}/nix/profile${dash_suffix}"
      else
        cfg.homeDirectory + "/.nix-profile${dash_suffix}");

    home.sessionVariablesFileName = "hm${dash_suffix}session-vars.sh";
    home.sessionVariablesGuardVar = "__HM_${upper_suffix}SESS_VARS_SOURCED";
    home.pathName = "home-manager${dash_suffix_}path";
    home.gcLinkName = "current-home${dash_suffix}";
    home.generationLinkNamePrefix = "home-manager${dash_suffix}";
  };

}

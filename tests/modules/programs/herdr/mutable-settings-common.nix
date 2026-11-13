{
  withPackage ? false,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  activation = config.home.activation.herdrMutableSettings;
  herdrBin = if withPackage then lib.escapeShellArg (lib.getExe pkgs.herdr) else "herdr";
in
{
  programs.herdr = {
    enable = true;
    package = lib.mkIf (!withPackage) null;
    mutableSettings = true;
    settings = {
      onboarding = false;
      theme.name = "catppuccin";
      keys.next_tab = [ "prefix+n" ];
    };
  };
  xdg.configHome = "${config.home.homeDirectory}/custom-config";

  assertions = [
    {
      assertion = activation.after == [ "linkGeneration" ] && activation.before == [ ];
      message = "Mutable Herdr settings must run after linkGeneration.";
    }
    {
      assertion = lib.hasInfix "display_path=${lib.escapeShellArg "/home/hm-user/custom-config/herdr/config.toml"}\n" activation.data;
      message = "Mutable Herdr settings must merge into the configured XDG destination.";
    }
    {
      assertion = !(config.xdg.configFile ? "herdr/config.toml");
      message = "Mutable Herdr settings must not be owned by xdg.configFile.";
    }
    {
      assertion = !(config.home.activation ? herdrImmutableSettings);
      message = "Mutable Herdr settings must not register immutable cleanup.";
    }
    {
      assertion = lib.hasSuffix "run ${herdrBin} server reload-config || true\n" activation.data;
      message = "Mutable Herdr settings must reload after merging, using the configured executable.";
    }
    {
      assertion = lib.elem pkgs.herdr config.home.packages == withPackage;
      message = "Herdr must only be installed when a package is configured.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-files/custom-config/herdr/config.toml
    settings="$(grep -m1 -o '/nix/store/[^ ]*-herdr-config.toml' "$TESTED/activate")" \
      || fail "Missing herdr-config.toml input"
    assertFileContent "$settings" ${./mutable-settings-expected.toml}
  '';
}

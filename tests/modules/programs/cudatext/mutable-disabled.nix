{ config, pkgs, ... }:
{
  programs.cudatext = {
    enable = false;
    package = null;
    mutableSettings = true;
    userSettings.numbers_style = 2;
  };

  assertions = [
    {
      assertion = config.programs.cudatext.mutableSettings;
      message = "Mutable CudaText settings must remain enabled while the module is disabled.";
    }
    {
      assertion = !(config.home.activation ? cudatextSettings);
      message = "Disabled CudaText must not register mutable settings activation.";
    }
    {
      assertion = !(config.home.activation ? cudatextImmutableSettings);
      message = "Disabled CudaText must not register immutable settings cleanup.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/${
      if pkgs.stdenv.hostPlatform.isDarwin then
        "Library/Application Support/CudaText"
      else
        ".config/cudatext"
    }/settings/user.json"
  '';
}

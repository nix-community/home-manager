{ config, pkgs, ... }:
{
  programs.cudatext = {
    enable = true;
    package = null;
    mutableSettings = true;
  };

  assertions = [
    {
      assertion = config.programs.cudatext.mutableSettings;
      message = "Mutable CudaText settings must remain enabled for an empty configuration.";
    }
    {
      assertion = !(config.home.activation ? cudatextSettings);
      message = "Empty CudaText settings must not register mutable settings activation.";
    }
    {
      assertion = !(config.home.activation ? cudatextImmutableSettings);
      message = "Empty CudaText settings must not register immutable settings cleanup.";
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

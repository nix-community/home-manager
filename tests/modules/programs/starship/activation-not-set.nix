{
  config,
  lib,
  ...
}:

{
  imports = [ ./stubs.nix ];

  programs.starship = {
    enable = true;
    validation.enable = true;
  };

  assertions = [
    {
      assertion = !lib.hasAttr "validateStarshipConfig" config.home.activation;
      message = "the validateStarshipConfig activation hook should not be defined when programs.starship.settings is not set";
    }
  ];
}

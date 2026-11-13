{
  config,
  lib,
  ...
}:
let
  cleanup = config.home.activation.antigravityImmutableSettings or null;
  activation = config.home.activation.antigravitySettings or null;
in
{
  programs.antigravity-cli = {
    enable = true;
    package = null;
    permissions = {
      allow = null;
      deny = [ "command(curl)" ];
    };
  };
  assertions = [
    {
      assertion = !config.programs.antigravity-cli.mutableSettings;
      message = "Antigravity permissions must default to immutable settings ownership.";
    }
    {
      assertion = activation == null && cleanup != null;
      message = "Immutable Antigravity permissions must schedule cleanup, not a merge.";
    }
    {
      assertion = cleanup.after == [ "writeBoundary" ] && cleanup.before == [ "linkGeneration" ];
      message = "Antigravity cleanup must run between writeBoundary and linkGeneration.";
    }
    {
      assertion =
        lib.hasInfix ''"$HOME"/.gemini/antigravity-cli/settings.json'' cleanup.data
        && lib.hasInfix (builtins.unsafeDiscardStringContext (
          toString config.home.file.".gemini/antigravity-cli/settings.json".source
        )) cleanup.data;
      message = "Antigravity cleanup must use the configured settings target and source.";
    }
  ];

  nmt.script = ''
    assertFileContent home-files/.gemini/antigravity-cli/settings.json ${./permissions-immutable-expected.json}
  '';
}

mode:

{ config, lib, ... }:

let
  redirected = mode == "cleanup-redirected";
  cleanup = config.home.activation.githubCopilotCliImmutableSettings or null;
  target = "copilot profile/declared.json";
in
{
  programs.github-copilot-cli = {
    enable = mode != "disabled";
    package = null;
    mutableSettings = lib.elem mode [
      "mutable-empty"
      "disabled"
    ];
    settings = lib.optionalAttrs (mode != "mutable-empty") {
      model = "claude-sonnet-4-5";
    };
    trustedFolders = lib.optionals (mode == "disabled") [ "/srv/projects" ];
  };

  home.file."${config.home.homeDirectory}/.copilot/settings.json" = lib.mkMerge [
    (lib.mkIf (mode == "cleanup-disabled") { enable = lib.mkForce false; })
    (lib.mkIf redirected {
      inherit target;
      source = lib.mkForce (builtins.toFile "copilot-overridden-settings.json" "{}\n");
    })
  ];

  nmt.script =
    assert !(config.home.activation ? githubCopilotCliSettings);
    assert !(config.home.activation ? githubCopilotCliTrustedFolders);
    assert (cleanup != null) == redirected;
    assert !redirected || cleanup.after == [ "writeBoundary" ];
    assert !redirected || cleanup.before == [ "linkGeneration" ];
    assert
      !redirected
      ||
        cleanup.data == lib.hm.generators.mkImpureConfigCleanup {
          file = config.home.file."${config.home.homeDirectory}/.copilot/settings.json";
        };
    ''
      assertPathNotExists home-files/.copilot/settings.json
      assertPathNotExists home-files/.copilot/config.json
    ''
    + lib.optionalString redirected ''
      assertFileContent "home-files/${target}" ${builtins.toFile "expected-overridden-settings.json" "{}\n"}
      assertFileContains activate '${target}'
    '';
}

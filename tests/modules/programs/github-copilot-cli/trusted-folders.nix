{
  config,
  lib,
  pkgs,
  ...
}:
let
  configPath = "/home/hm-user/copilot profile/config.json";
  merge = pkgs.writeShellScript "test-copilot-trusted-folders" ''
    set -euo pipefail
    errorEcho() { echo "$*" >&2; }
    ${lib.replaceStrings [ (lib.escapeShellArg configPath) ] [ ''"$PWD/profile/config.json"'' ]
      config.home.activation.githubCopilotCliTrustedFolders.data
    }
  '';
in
{
  programs.github-copilot-cli = {
    enable = true;
    package = null;
    configDir = "/home/hm-user/copilot profile";
    trustedFolders = [
      "/home/user/projects"
      "/home/user/other"
    ];
    # Not a user setting; only the warning points to trustedFolders.
    settings.trusted_folders = [ "/home/user/ignored" ];
  };

  test.asserts.warnings.expected = [
    ''
      programs.github-copilot-cli.settings: trusted_folders and trustedFolders
      are not written to settings.json. Copilot CLI keeps trusted folders in
      its own state; use programs.github-copilot-cli.trustedFolders instead.
    ''
  ];

  # The merge itself is covered by the mkImpureConfigMerger tests. This checks
  # the module's wiring and its union of trusted folders.
  nmt.script =
    assert !(config.home.activation ? githubCopilotCliSettings);
    assert config.home.activation.githubCopilotCliTrustedFolders.after == [ "linkGeneration" ];
    ''
      assertPathNotExists home-files/.copilot/settings.json
      assertPathNotExists home-files/.copilot/config.json
      assertFileContains activate '${configPath}'
      assertFileRegex activate '/bin/pyjson5 --as-json'

      mkdir profile
      umask 022
      "${merge}"
      test "$(stat -c '%a' profile/config.json)" = 600
      ${lib.getExe pkgs.jaq} -e '
        . == { trustedFolders: ["/home/user/projects", "/home/user/other"] }
      ' profile/config.json > /dev/null
      cat > profile/config.json <<'JSON'
      // User settings belong in settings.json.
      {
        loggedInUsers: [{ login: "user" }],
        trustedFolders: ["/srv/interactive", "/home/user/projects"],
      }
      JSON
      "${merge}"
      ${lib.getExe pkgs.jaq} -e '
        .loggedInUsers == [{ login: "user" }]
        and .trustedFolders == ["/srv/interactive", "/home/user/projects", "/home/user/other"]
      ' profile/config.json > /dev/null
    '';
}

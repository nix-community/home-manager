{ ... }:
{
  programs.delta = {
    enable = true;
    settings = {
      features = "decorations";
      whitespace-error-style = "22 reverse";
      decorations = {
        commit-decoration-style = "bold yellow box ul";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
      };
    };
  };

  nmt.script = ''
    # deltaWrapper=$(readlink -f home-files/.nix-profile/bin/delta)
    # assertFileExists home-files/.nix-profile/bin/delta
    # deltaConfig=$(grep -o 'export --context="[^"]*"' "$deltaWrapperFile" | cut -d'"' -f2)
    # assertFileExists "$deltaConfig"
    # assertFileContent "$deltaConfig" ${./example-settings-expected.conf}
  '';
}

{ pkgs, ... }:
{
  programs = {
    mise = {
      package = pkgs.writeShellScriptBin "mise" ''
        if [ "$1" = "completion" ]; then
          echo "complete -F _mise mise"
        fi
      '';
      enable = true;
      enableBashIntegration = true;
    };

    bash.enable = true;
  };

  nmt.script = ''
    assertFileRegex home-files/.bashrc 'eval "$(/nix/store/.*mise.*/bin/mise activate bash)"'
    assertFileRegex home-files/.bashrc \
      '^source /nix/store/[0-9a-z]*-mise-bash-completion.bash$'
  '';
}

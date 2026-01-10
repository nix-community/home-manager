{ pkgs, ... }:
{
  services.proton-pass-agent = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.fish.enable = true;

  nmt.script = ''
    fish_config=home-files/.config/fish/config.fish

    assertFileContains $fish_config \
      'if test -z "$SSH_AUTH_SOCK"; or test -z "$SSH_CONNECTION'
    assertFileContains $fish_config \
      'set -x SSH_AUTH_SOCK ${
        if pkgs.stdenv.hostPlatform.isDarwin then
          "$(@getconf-system_cmds@/bin/getconf DARWIN_USER_TEMP_DIR)"
        else
          "$XDG_RUNTIME_DIR"
      }/proton-pass-agent'
  '';
}

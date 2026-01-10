{ pkgs, ... }:
{
  services.proton-pass-agent = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.bash.enable = true;

  nmt.script = ''
    bash_profile=home-files/.profile

    assertFileContains $bash_profile \
      'if [ -z "$SSH_AUTH_SOCK" -o -z "$SSH_CONNECTION" ]; then'
    assertFileContains $bash_profile \
      'export SSH_AUTH_SOCK=${
        if pkgs.stdenv.hostPlatform.isDarwin then
          "$(@getconf-system_cmds@/bin/getconf DARWIN_USER_TEMP_DIR)"
        else
          "$XDG_RUNTIME_DIR"
      }/proton-pass-agent'
  '';
}

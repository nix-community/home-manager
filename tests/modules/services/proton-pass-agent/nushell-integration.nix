{ pkgs, ... }:
{
  services.proton-pass-agent = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.nushell.enable = true;

  nmt.script =
    let
      unsetOrEmpty = var: ''("${var}" not-in $env) or ($env.${var} | is-empty)'';
    in
    ''
      nu_config=home-files/.config/nushell/config.nu

      assertFileContains $nu_config \
        'if ${unsetOrEmpty "SSH_AUTH_SOCK"} or ${unsetOrEmpty "SSH_CONNECTION"} {'
      assertFileContains $nu_config \
        '$env.SSH_AUTH_SOCK = $"${
          if pkgs.stdenv.hostPlatform.isDarwin then
            "(@getconf-system_cmds@/bin/getconf DARWIN_USER_TEMP_DIR)"
          else
            "($env.XDG_RUNTIME_DIR)"
        }/proton-pass-agent"'
    '';
}

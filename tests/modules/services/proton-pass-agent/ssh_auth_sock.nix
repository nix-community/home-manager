{ pkgs, ... }:

{
  programs.bash.enable = true;
  programs.fish.enable = true;
  programs.nushell.enable = true;
  programs.zsh.enable = true;
  services.proton-pass-agent.enable = true;

  nmt.script =
    let
      bashDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "$(@system_cmds@/bin/getconf DARWIN_USER_TEMP_DIR)"
        else
          "$XDG_RUNTIME_DIR";
      fishDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "$(@system_cmds@/bin/getconf DARWIN_USER_TEMP_DIR)"
        else
          "$XDG_RUNTIME_DIR";
      nushellDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "(@system_cmds@/bin/getconf DARWIN_USER_TEMP_DIR)"
        else
          "($env.XDG_RUNTIME_DIR)";
    in
    ''
      assertFileContains \
        home-files/.profile \
        'export SSH_AUTH_SOCK="${bashDir}/proton-pass-agent"'
      assertFileContains \
        home-files/.config/fish/config.fish \
        'set -x SSH_AUTH_SOCK "${fishDir}/proton-pass-agent"'
      assertFileContains \
        home-files/.config/nushell/config.nu \
        '$env.SSH_AUTH_SOCK = $"${nushellDir}/proton-pass-agent"'
      assertFileContains \
        home-files/.zshenv \
        'export SSH_AUTH_SOCK="${bashDir}/proton-pass-agent"'
    '';
}

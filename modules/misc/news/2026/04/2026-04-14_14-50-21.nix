_: {
  time = "2026-04-14T09:20:21+00:00";
  # condition = pkgs.stdenv.hostPlatform.isLinux;
  # condition = config.programs.neovim.enable;
  condition = true;
  # if behavior changed, explain how to restore previous behavior.
  message = ''
    A new module is available: 'programs.dprint'.

    dprint is a code formatter written in rust.
    It allows formatting toml, markdown, yaml, and many other filetypes.
    See https://dprint.dev/ for more.
  '';
}

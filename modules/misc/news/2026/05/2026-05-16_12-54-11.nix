{
  time = "2026-05-16T19:54:11+00:00";
  condition = true;
  message = ''
    A new module is available: 'programs.sh'. 'programs.sh' will control all POSIX compatible shells (e.g. dash, bash, zsh, etc.).

    For now, 'programs.sh' is enabled by default if 'programs.bash' is enabled for backwards compatibilty.

    This also means a breaking change: bash's configuration is now stored in '~/.bash-profile' and '~/.bashrc' *only*. Since 'programs.sh' is enabled by default if bash is enabled, this should not be a problem, but is something to be aware of.

    If you were using 'programs.bash' to configure the POSIX shells, this you should move that configuration into 'programs.sh'.
  '';
}

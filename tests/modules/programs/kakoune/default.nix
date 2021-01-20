{
  kakoune-no-plugins = ./no-plugins.nix;
  # Temporarily disabled until https://github.com/NixOS/nixpkgs/pull/110196
  # reaches the unstable channel.
  # kakoune-use-plugins = ./use-plugins.nix;
  kakoune-whitespace-highlighter = ./whitespace-highlighter.nix;
  kakoune-whitespace-highlighter-corner-cases =
    ./whitespace-highlighter-corner-cases.nix;
}

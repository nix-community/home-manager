{ pkgs, ... }:
{
  time = "2026-07-15T21:56:32+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    The config path for 'senpai' on Darwin now defaults to:
      ~/Library/Application Support/senpai/senpai.scfg
  '';
}

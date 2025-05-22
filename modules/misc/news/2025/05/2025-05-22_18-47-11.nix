{ pkgs, ... }:
{
  time = "2025-05-22T23:47:11+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new sketchybar module has been added.

    - Simple configuration with a single `config` option that accepts the
      configuration as lines, a file, or a directory.
    - Support for both bash and lua configuration types
    - `extraLuaPackages` option for additional Lua dependencies
    - `extraPackages` option for additional runtime dependencies
    - Integrated launchd service management
  '';
}

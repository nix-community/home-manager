{
  sketchybar = ./sketchybar.nix; # Bash configuration with validation
  sketchybar-lua-config = ./sketchybar-lua-config.nix; # Lua configuration with validation
  sketchybar-invalid-lua-config = ./sketchybar-invalid-lua-config.nix; # Tests error on missing sbarLua
  sketchybar-service-integration = ./sketchybar-service-integration.nix; # Service integration with validation
}

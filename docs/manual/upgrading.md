# Home Manager Channel Upgrade Guide for NixOS 25.05

## Overview

When upgrading NixOS to a new major version (e.g., from 24.11 to 25.05), you also need to upgrade your Home Manager channel to maintain compatibility. This guide covers the proper steps to upgrade Home Manager channels for NixOS 25.05.

## Understanding Home Manager Versioning

Home Manager follows NixOS release cycles and provides corresponding branches:
- **release-##.##**: Stable branch for NixOS ##.## (current stable)
- **master**: Development branch (tracks nixos-unstable)

> **Important**: Always use the Home Manager version that matches your NixOS version to avoid compatibility issues.

## Method 1: Channel-Based Installation (Traditional)

### Step 1: Check Current Channels

First, verify your current Home Manager channel:

```bash
nix-channel --list
```

You should see something like:
```
home-manager https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz
```
### Step 2: Update Home Manager Channel

Replace the old channel with the NixOS 25.05 compatible version:

```bash
# Add new 25.05 channel
nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager

# Update channels
nix-channel --update
```

### Step 3: Apply the Changes

```bash
home-manager switch
```

## Method 2: Flake-Based Installation (Modern)

If you're using Home Manager with Nix flakes, update your `flake.nix`:

```nix
{
  description = "Home Manager configuration";

  inputs = {
    # Increment release branch for NixOS
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      # Follow corresponding `release` branch from Home Manager
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {
    homeConfigurations."yourusername" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./home.nix ];
    };
  };
}
```

Then update and rebuild:

```bash
nix flake update
# Standalone
home-manager switch --flake .
# Nixos module 
sudo nixos-rebuild switch
```

## Method 3: NixOS Module Integration

If you're using Home Manager as a NixOS module, update your system configuration:

```nix
# In your configuration.nix or flake.nix
{
  imports = [
    (builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz/nixos")
  ];

  # Your home-manager configuration
  home-manager.users.yourusername = { pkgs, ... }: {
    home.stateVersion = "25.05";
    # ... rest of your configuration
  };
}
```

Then rebuild your system:

```bash
sudo nixos-rebuild switch
```

## Important: State Version Management

> [!WARNING]      
> ⚠️ Careful updating your `home.stateVersion` when upgrading Home Manager 

The `stateVersion` is best to remain set to the NixOS version you **first installed** Home Manager   

```nix
{
  home.stateVersion = "24.11";  # Example: if you first installed on 24.11
}
```

**Why?** The `stateVersion` ensures backward compatibility and prevents breaking changes from affecting your existing configuration.

**Remember:** Channel version ≠ State version. Update the channel, keep the `stateVersion` unchanged. Advanced users can view the changes between releases and see if any of the `stateVersion` changes will affect them and increment, if they migrate their configurations to follow the changed evaluation. 

## Troubleshooting

### Common Issues

1. **Version Mismatch Warning**: If you see warnings about version mismatches, ensure your Home Manager version matches your NixOS version.

2. **Build Failures**: Some packages may have changed between versions. Check the [Home Manager release notes](https://nix-community.github.io/home-manager/release-notes.xhtml) for breaking changes.

3. **Channel Not Found**: If `nix-channel --list` shows no channels, you might be using a different installation method (like flakes or NixOS module).

### Verification

After upgrading, verify the installation:

```bash
home-manager --version
```

This should show version 25.05 or indicate it's using the release-25.05 branch.

## Additional Resources

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS 25.05 Release Notes](https://nixos.org/manual/nixos/stable/release-notes)
- [Home Manager Release Notes](https://nix-community.github.io/home-manager/release-notes.xhtml)

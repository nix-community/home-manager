{ config, lib, pkgs, ... }:

with lib;

let

  fooPluginSrc = pkgs.writeText "fooPluginSrc" "";

  generatedConfdFile = pkgs.writeText "plugin-foo.fish" ''
    # Plugin foo
    set -l plugin_dir ${fooPluginSrc}

    # Set paths to import plugin components
    if test -d $plugin_dir/functions
      set fish_function_path $fish_function_path[1] $plugin_dir/functions $fish_function_path[2..-1]
    end

    if test -d $plugin_dir/completions
      set fish_complete_path $fish_complete_path[1] $plugin_dir/completions $fish_complete_path[2..-1]
    end

    # Source initialization code if it exists.
    if test -d $plugin_dir/conf.d
      for f in $plugin_dir/conf.d/*.fish
        source $f
      end
    end

    if test -f $plugin_dir/key_bindings.fish
      source $plugin_dir/key_bindings.fish
    end

    if test -f $plugin_dir/init.fish
      source $plugin_dir/init.fish
    end
  '';

in {
  config = {
    programs.fish = {
      enable = true;

      plugins = [{
        name = "foo";
        src = fooPluginSrc;
      }];
    };

    # Needed to avoid error with dummy fish package.
    xdg.dataFile."fish/home-manager_generated_completions".source =
      lib.mkForce (builtins.toFile "empty" "");

    test.stubs.fish = { };

    nmt = {
      description =
        "if fish.plugins set, check conf.d file exists and contents match";
      script = ''
        assertDirectoryExists home-files/.config/fish/conf.d
        assertFileExists home-files/.config/fish/conf.d/plugin-foo.fish
        assertFileContent home-files/.config/fish/conf.d/plugin-foo.fish ${generatedConfdFile}
      '';

    };
  };
}

{ config, pkgs, ... }:
let
  expectedContent = "something important";
in
{
  programs = {
    direnv = {
      enable = true;
      silent = true;

      enableBashIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;

      mise = {
        enable = true;
        package = config.lib.test.mkStubPackage { name = "mise"; };
      };

      nix-direnv = {
        enable = true;
        package = config.lib.test.mkStubPackage {
          buildScript = ''
            mkdir -p $out/share/nix-direnv/
            echo "use_nix" >> $out/share/nix-direnv/direnvrc
          '';
        };
      };

      stdlib = expectedContent;

      config = {
        global = {
          hide_env_diff = true;
        };
        whitelist = {
          prefix = [ "/home/user/projects" ];
        };
      };
    };

    bash.enable = true;
    fish.enable = true;
    nushell.enable = true;
    zsh.enable = true;
  };

  nmt.script =
    let
      nushellConfigFile =
        if pkgs.stdenv.isDarwin && !config.xdg.enable then
          "home-files/Library/Application Support/nushell/config.nu"
        else
          "home-files/.config/nushell/config.nu";
    in
    # Bash
    ''
      # Test basic bash integration
      assertFileExists home-files/.bashrc
      assertFileRegex \
        home-files/.bashrc \
        'eval "\$(@direnv@/bin/direnv hook bash)"'


      # Test nushell integration
      assertFileExists "${nushellConfigFile}"
      assertFileRegex "${nushellConfigFile}" '@direnv@/bin/direnv export json'

      # Test creates config file
      assertFileExists home-files/.config/direnv/direnv.toml
      assertFileContent \
        home-files/.config/direnv/direnv.toml \
        ${./toml-config-expected.toml}

      assertFileExists home-files/.config/direnv/lib/hm-nix-direnv.sh
      assertFileRegex home-files/.config/direnv/lib/hm-nix-direnv.sh \
      'use_nix'

      assertFileRegex \
        home-files/.config/direnv/direnvrc \
        '${expectedContent}'
      # Test bash integration
      assertFileRegex home-files/.bashrc \
        'eval.*direnv hook bash'

      # Test zsh integration
      assertFileRegex home-files/.zshrc \
        'eval.*direnv hook zsh'

      # Test fish integration (enabled by default)
      assertFileRegex home-files/.config/fish/config.fish \
        'direnv hook fish.*source'

      # Test nushell integration
      assertFileRegex "${nushellConfigFile}" \
        'direnv export json'
      assertFileRegex "${nushellConfigFile}" \
        'load-env'

      # Test mise integration creates library file
      assertFileExists home-files/.config/direnv/lib/hm-mise.sh
      assertFileRegex home-files/.config/direnv/lib/hm-mise.sh \
        'mise direnv activate'

    '';
}

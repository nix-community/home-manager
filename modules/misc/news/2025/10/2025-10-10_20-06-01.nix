{
  time = "2025-10-11T00:06:01+00:00";
  condition = true;
  message = ''
    A new option is availabe: `home-manager.minimal`

    By default, Home Manager imports all modules, which leads to increased
    evaluation time. Some users may wish to only import the modules they
    actually use. When the new option is enabled, Home Manager will only
    import the basic set of modules it requires to function. Other modules
    will have to be enabled manually, like this:

    ```nix
      imports = [
        "''${modulesPath}/programs/fzf.nix"
      ];
    ```

    This entrypoint is only recommended for advanced users, who are
    comfortable maintaining a personal list of modules to import.
  '';
}

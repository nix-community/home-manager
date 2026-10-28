{
  time = "2025-10-25T21:37:46+00:00";
  condition = true;
  message = ''
    A new module is available: `programs.go-freeze`

    `go-freeze` is a CLI tool that to generate mages of code and terminal
    output.

    This module allows for defining named configuration files via
    `settings.<name>` attributes, ex.

    ```nix
    {
      programs.go-freeze = {
        enable = true;

        settings.user = {
          theme = "gruvbox-dark";
        };
      };
    }
    ```

    ...  which may be activated at runtime by name;

    ```bash
    go-freeze -c user -l bash <<<'echo "hello world"';
    ```
  '';
}

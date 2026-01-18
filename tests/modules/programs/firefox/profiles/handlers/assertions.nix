modulePath:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    {
      test.asserts.assertions.expected = [
        "'x-test/action-2-requires-handlers': handlers must be set when 'action' is set to 2 (Use helper app)."
        "'x-test/both-path-and-uri': handler can't have both 'path' and 'uriTemplate' set."
        "'x-test/empty-handler-only': an empty handler can only be used when there are additional handlers."
        "'x-test/handler-with-name-no-path-or-uri': handler has a 'name' but no 'path' or 'uriTemplate'."
        "'x-test/handlers-without-action-2': handlers can only be set when 'action' is set to 2 (Use helper app)."
        "'x-test/only-first-handler-empty': only the first handler can be empty, to indicate no default."
        "'test+action-2-requires-handlers': handlers must be set when 'action' is set to 2 (Use helper app)."
        "'test+both-path-and-uri': handler can't have both 'path' and 'uriTemplate' set."
        "'test+empty-handler-only': an empty handler can only be used when there are additional handlers."
        "'test+handler-with-name-no-path-or-uri': handler has a 'name' but no 'path' or 'uriTemplate'."
        "'test+handlers-without-action-2': handlers can only be set when 'action' is set to 2 (Use helper app)."
        "'test+only-first-handler-empty': only the first handler can be empty, to indicate no default."
      ];
    }
    // lib.setAttrByPath modulePath {
      enable = true;

      profiles.test = {
        id = 0;
        handlers = lib.mkMerge [
          # Empty handlers list with action=2
          (
            (cfg: {
              mimeTypes."x-test/action-2-requires-handlers" = cfg;
              schemes."test+action-2-requires-handlers" = cfg;
            })
            {
              action = 2;
              handlers = [ ];
            }
          )

          # Handler with both path and uriTemplate
          (
            (cfg: {
              mimeTypes."x-test/both-path-and-uri" = cfg;
              schemes."test+both-path-and-uri" = cfg;
            })
            {
              action = 2;
              handlers = [
                {
                  name = "Test";
                  path = "${pkgs.hello}/bin/hello";
                  uriTemplate = "https://example.com/?url=%s";
                }
              ];
            }
          )

          # Single empty handler
          (
            (cfg: {
              mimeTypes."x-test/empty-handler-only" = cfg;
              schemes."test+empty-handler-only" = cfg;
            })
            {
              action = 2;
              handlers = [ { } ];
            }
          )

          # Handler with name but no path/uriTemplate
          (
            (cfg: {
              mimeTypes."x-test/handler-with-name-no-path-or-uri" = cfg;
              schemes."test+handler-with-name-no-path-or-uri" = cfg;
            })
            {
              action = 2;
              handlers = [
                {
                  name = "Test Handler";
                }
              ];
            }
          )

          # Action != 2 but has handlers
          (
            (cfg: {
              mimeTypes."x-test/handlers-without-action-2" = cfg;
              schemes."test+handlers-without-action-2" = cfg;
            })
            {
              action = 1;
              handlers = [
                {
                  name = "Test";
                  path = "${pkgs.hello}/bin/hello";
                }
              ];
            }
          )

          # Multiple handlers with second one empty
          (
            (cfg: {
              mimeTypes."x-test/only-first-handler-empty" = cfg;
              schemes."test+only-first-handler-empty" = cfg;
            })
            {
              action = 2;
              handlers = [
                {
                  name = "Default App";
                  path = "${pkgs.hello}/bin/hello";
                }
                { }
              ];
            }
          )
        ];
      };
    }
  );
}

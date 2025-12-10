{
  config,
  lib,
  pkgs,
  appName,
  package,
  modulePath,
  profilePath,
}:
let
  jsonFormat = pkgs.formats.json { };

  # Process configuration, remove null values and empty handlers arrays.
  genCfg =
    cfg:
    lib.mapAttrs (
      _: item:
      (removeAttrs item [ "handlers" ])
      // (lib.optionalAttrs (item.handlers != [ ]) {
        handlers = map (handler: lib.filterAttrsRecursive (_: v: v != null) handler) item.handlers;
      })
    ) cfg;

  # Generate validation assertions for a configuration
  genAssertions =
    cfg:
    lib.flatten (
      lib.attrValues (
        lib.mapAttrs (
          cfgName: value:
          (map (
            { path, uriTemplate, ... }:
            {
              assertion = path == null || uriTemplate == null;
              message = "'${cfgName}': handler can't have both 'path' and 'uriTemplate' set.";
            }
          ) value.handlers)
          ++ (map (
            {
              name,
              path,
              uriTemplate,
            }:
            {
              assertion = name != null -> (path != null || uriTemplate != null);
              message = "'${cfgName}': handler has a 'name' but no 'path' or 'uriTemplate'.";
            }
          ) value.handlers)
          ++ (lib.imap0 (idx: handler: {
            assertion =
              idx != 0
              ->
                handler != {
                  name = null;
                  path = null;
                  uriTemplate = null;
                };
            message = "'${cfgName}': only the first handler can be empty, to indicate no default.";
          }) value.handlers)
          ++ [
            {
              assertion = value.action != 2 -> value.handlers == [ ];
              message = "'${cfgName}': handlers can only be set when 'action' is set to 2 (Use helper app).";
            }
            {
              assertion = value.action == 2 -> value.handlers != [ ];
              message = "'${cfgName}': handlers must be set when 'action' is set to 2 (Use helper app).";
            }
            {
              assertion =
                value.action == 2
                -> (
                  (builtins.length value.handlers) == 1
                  -> (
                    (builtins.elemAt value.handlers 0) != {
                      name = null;
                      path = null;
                      uriTemplate = null;
                    }
                  )
                );
              message = "'${cfgName}': an empty handler can only be used when there are additional handlers.";
            }
          ]
        ) cfg
      )
    );

  # Common options shared between mimeTypes and schemes
  commonHandlerOptions = {
    action = lib.mkOption {
      type = lib.types.enum [
        0
        1
        2
        3
        4
      ];
      default = 1;
      description = ''
        The action to take for this MIME type / URL scheme. Possible values:
        - 0: Save file
        - 1: Always ask
        - 2: Use helper app
        - 3: Open in ${appName}
        - 4: Use system default
      '';
    };

    ask = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        If true, the user is asked what they want to do with the file.
        If false, the action is taken without user intervention.
      '';
    };

    handlers = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                Display name of the handler.
              '';
            };

            path = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                Path to the executable to be used.

                Only one of 'path' or 'uriTemplate' should be set.
              '';
            };

            uriTemplate = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                URI for the application handler.

                Only one of 'path' or 'uriTemplate' should be set.
              '';
            };
          };
        }
      );
      default = [ ];
      description = ''
        An array of handlers with the first one being the default.
        If you don't want to have a default handler, use an empty object for the first handler.
        Only valid when action is set to 2 (Use helper app).
      '';
    };
  };
in
{
  imports = [ (pkgs.path + "/nixos/modules/misc/meta.nix") ];

  meta.maintainers = with lib.maintainers; [ kugland ];

  options = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.schemes != { } || config.mimeTypes != { };
      internal = true;
    };

    force = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to force replace the existing handlers configuration.
      '';
    };

    mimeTypes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = commonHandlerOptions // {
            extensions = lib.mkOption {
              type = lib.types.listOf (lib.types.strMatching "^[^\\.].+$");
              default = [ ];
              example = [
                "jpg"
                "jpeg"
              ];
              description = ''
                List of file extensions associated with this MIME type.
              '';
            };
          };
        }
      );
      default = { };
      example = lib.literalExpression ''
        {
          "application/pdf" = {
            action = 2;
            ask = false;
            handlers = [
              {
                name = "Okular";
                path = "''${pkgs.okular}/bin/okular";
              }
            ];
            extensions = [ "pdf" ];
          };
        }
      '';
      description = ''
        Attribute set mapping MIME types to their handler configurations.
      '';
    };

    schemes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = commonHandlerOptions;
        }
      );
      default = { };
      example = lib.literalExpression ''
        {
          mailto = {
            action = 2;
            ask = false;
            handlers = [
              {
                name = "Gmail";
                uriTemplate = "https://mail.google.com/mail/?extsrc=mailto&url=%s";
              }
            ];
          };
        }
      '';
      description = ''
        Attribute set mapping URL schemes to their handler configurations.
      '';
    };

    assertions = lib.mkOption {
      type = lib.types.listOf lib.types.unspecified;
      internal = true;
      readOnly = true;
      default = (genAssertions config.mimeTypes) ++ (genAssertions config.schemes);
      description = ''
        Validation assertions for handler configuration.
      '';
    };

    finalSettings = lib.mkOption {
      type = jsonFormat.type;
      internal = true;
      readOnly = true;
      default = {
        defaultHandlersVersion = { };
        isDownloadsImprovementsAlreadyMigrated = false;
        mimeTypes = genCfg config.mimeTypes;
        schemes = genCfg config.schemes;
      };
      description = ''
        Resulting handlers.json settings.
      '';
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      internal = true;
      readOnly = true;
      default = jsonFormat.generate "handlers.json" config.finalSettings;
      description = ''
        JSON representation of the handlers configuration.
      '';
    };
  };
}

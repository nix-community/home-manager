{ config, lib, ... }:
with lib; {
  options = {
    name = mkOption {
      type = types.str;
      example = "My INBOX";
      default = "My INBOX";
      description = "Name to display";
    };

    query = mkOption {
      type = types.str;
      example = "tag:inbox";
      default = "tag:inbox";
      description = "Notmuch query";
    };

    limit = mkOption {
      type = types.nullOr types.int;
      example = 10;
      default = null;
      description = "Restricts number of messages/threads in the result.";
    };

    type = mkOption {
      type = types.nullOr (types.enum ([ "threads" "messages" ]));
      example = "threads";
      default = null;
      description =
        "Reads all matching messages or whole-threads. The default is 'messages' or nm_query_type.";
    };
  };
}

let
  actionKey = "__homeManagerMutableConfig_action";
in
{
  remove = {
    ${actionKey} = "remove";
  };

  union = items: {
    ${actionKey} = "union";
    inherit items;
  };

  mergeBy = keys: items: {
    ${actionKey} = "mergeBy";
    keys = if builtins.isList keys then keys else [ keys ];
    inherit items;
  };
}

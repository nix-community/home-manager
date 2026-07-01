''
  def mergeOpenClawSettings($live; $declared):
    if ($live | type) == "object" and ($declared | type) == "object" then
      reduce (($live + $declared) | keys_unsorted[]) as $key
        ({};
          .[$key] =
            if ($live | has($key)) and ($declared | has($key)) then
              mergeOpenClawSettings($live[$key]; $declared[$key])
            elif ($declared | has($key)) then
              $declared[$key]
            else
              $live[$key]
            end
        )
    elif ($live | type) == "array" and ($declared | type) == "array" then
      if
        (all($live[]?; type == "object" and has("id")))
        and (all($declared[]?; type == "object" and has("id")))
      then
        ($live | map({ key: (.id | tostring), value: . }) | from_entries) as $liveById
        | [
            $declared[]? as $item
            | if $liveById | has($item.id | tostring) then
                mergeOpenClawSettings($liveById[$item.id | tostring]; $item)
              else
                $item
              end
          ] as $mergedDeclared
        | reduce ($live[]?) as $item
            ($mergedDeclared; if any(.[]; .id == $item.id) then . else . + [$item] end)
      else
        reduce ($live[]?) as $item
          ($declared; if any(.[]; . == $item) then . else . + [$item] end)
      end
    else
      $declared
    end;

  mergeOpenClawSettings(.[0]; .[1])
''


```shell
jq -r '.base_array | map({field1, field2, field3: .array.field3, field4: .array.field4}) | (first | keys_unsorted) as $keys | map([to_entries[] | .value]) as $rows | $keys,$rows[] | @csv' input.json
```
Get fields 1 and 2 from `.base_array` (Eq to `.base_array[].field1`). To get layer down use `name: array.field3` (Eq to `.base_array[].array.field3` with name `name`)

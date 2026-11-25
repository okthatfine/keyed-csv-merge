///|
test "disjoint edits survive reordered headers and rows" {
  let r = merge_report(
    "id,x,y\na,1,2\nb,3,4", "x,id,y\n3,b,4\n10,a,2", "id,x,y\na,1,20\nb,3,4", "id",
  )
  assert_eq(r.csv, Some("id,x,y\r\na,10,20\r\nb,3,4\r\n"))
}

///|
test "divergent writes identify the exact cell and preserve both alternatives" {
  let r = merge_report("id,x\na,z", "id,x\na,A", "id,x\na,B", "id")
  assert_eq(r.csv, None)
  assert_eq(r.conflicts.length(), 1)
  assert_eq(r.conflicts[0].key, "a")
  assert_eq(r.conflicts[0].column, Some("x"))
  assert_eq(r.conflicts[0].left, Some(["A"]))
  assert_eq(r.conflicts[0].right, Some(["B"]))
}

///|
test "matching additions coalesce while delete versus edit is explicit" {
  let r = merge_report("id,x\na,z", "id,x\nb,w", "id,x\na,zz\nb,w", "id")
  assert_eq(r.conflicts.length(), 1)
  assert_eq(r.conflicts[0].reason, "delete/edit")
  assert_eq(r.conflicts[0].left, None)
  let clean = merge_report("id,x\na,z", "id,x\nb,w", "id,x\na,z\nb,w", "id")
  assert_eq(clean.csv, Some("id,x\r\nb,w\r\n"))
}

///|
test "concurrent additions with incompatible values conflict" {
  let r = merge_report("id,x", "id,x\na,1", "id,x\na,2", "id")
  assert_eq(r.conflicts[0].reason, "add/add")
}

///|
test "invalid snapshots cannot be treated as deleted rows" {
  for
    bad in ["id,x\na,1\na,2", "id,x\na", "id,x\n,1", "id,id\na,b", "id,z\na,1"] {
    assert_eq(merge_report("id,x", bad, "id,x", "id").status, "invalid")
  }
}

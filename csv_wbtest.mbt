///|
test "CSV round trip preserves arbitrary combinations of quoted field contents" {
  let atoms = ["", "abc", "雪", "😀", ",", "\"", "\r", "\n", "a\r\nb", " a "]
  for x in atoms {
    for y in atoms {
      let rows = [["id", "value"], ["001", x + y], ["002", y + x]]
      assert_eq(parse_csv(encode_csv(rows)), Ok(rows))
    }
  }
}

///|
test "one BOM, mixed record endings and escaped quote at end of file" {
  assert_eq(
    parse_csv("\u{FEFF}id,v\r1,a\r\n2,\"a\"\"\""),
    Ok([["id", "v"], ["1", "a"], ["2", "a\""]]),
  )
}

///|
test "malformed quoting is rejected before merge" {
  for s in ["id\nopen\"quote", "id\n\"open", "id\n\"closed\"junk"] {
    assert_true(parse_csv(s) is Err(_))
  }
}

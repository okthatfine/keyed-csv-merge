///|
fn parse_csv(input : String) -> Result[Array[Array[String]], String] {
  let records : Array[Array[String]] = []
  let mut row : Array[String] = []
  let mut field = StringBuilder::new()
  let mut quoted = false
  let mut after_quote = false
  let mut after_cr = false
  let mut started = false
  let mut first = true
  for ch in input {
    if first {
      first = false
      if ch == '\u{FEFF}' { continue }
    }
    if after_cr {
      after_cr = false
      if ch == '\n' { continue }
    }
    if quoted {
      if ch == '"' {
        quoted = false
        after_quote = true
      } else {
        field.write_char(ch)
      }
      continue
    }
    if ch == ',' || ch == '\r' || ch == '\n' {
      row.push(field.to_string())
      field = StringBuilder::new()
      started = false
      after_quote = false
      if ch != ',' {
        records.push(row)
        row = []
        after_cr = ch == '\r'
      }
    } else if ch == '"' && (!started || after_quote) {
      if after_quote { field.write_char('"') }
      quoted = true
      after_quote = false
      started = true
    } else if after_quote || ch == '"' {
      return Err("unexpected character at record " + (records.length() + 1).to_string())
    } else {
      started = true
      field.write_char(ch)
    }
  }
  if quoted { return Err("unterminated quoted field") }
  if started || row.length() > 0 {
    row.push(field.to_string())
    records.push(row)
  }
  Ok(records)
}

///|
fn encode_csv(rows : Array[Array[String]]) -> String {
  let out = StringBuilder::new()
  for row in rows {
    for i, value in row {
      if i > 0 { out.write_char(',') }
      let mut wrap = false
      for ch in value {
        if ch == '"' || ch == ',' || ch == '\n' || ch == '\r' { wrap = true }
      }
      if wrap { out.write_char('"') }
      for ch in value {
        if ch == '"' { out.write_char('"') }
        out.write_char(ch)
      }
      if wrap { out.write_char('"') }
    }
    out.write_string("\r\n")
  }
  out.to_string()
}

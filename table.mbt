///|
priv struct Table {
  header : Array[String]
  order : Array[String]
  rows : Map[String, Array[String]]
}

///|
fn load_table(text : String, key : String, schema : Array[String]?) -> Result[Table, String] {
  let records = match parse_csv(text) {
    Ok(v) => v
    Err(reason) => return Err(reason)
  }
  if records.is_empty() { return Err("missing header") }
  let header = records[0]
  let positions : Map[String, Int] = {}
  for i, col in header {
    if col.is_empty() || positions.contains(col) { return Err("empty or duplicate header: " + col) }
    positions[col] = i
  }
  let key_index = match positions.get(key) {
    Some(i) => i
    None => return Err("missing key column: " + key)
  }
  let canonical = schema.unwrap_or(header)
  if canonical.length() != header.length() { return Err("header columns differ") }
  let indexes : Array[Int] = []
  for col in canonical {
    match positions.get(col) {
      Some(i) => indexes.push(i)
      None => return Err("missing column: " + col)
    }
  }
  let order : Array[String] = []
  let rows : Map[String, Array[String]] = {}
  for r = 1; r < records.length(); r = r + 1 {
    let fields = records[r]
    if fields.length() != header.length() { return Err("wrong field count at record " + (r+1).to_string()) }
    let id = fields[key_index]
    if id.is_empty() || rows.contains(id) { return Err("empty or duplicate key at record " + (r+1).to_string()) }
    rows[id] = indexes.map(i => fields[i])
    order.push(id)
  }
  Ok({ header: canonical, order, rows })
}

///|
#derive(@json.ToJson)
priv struct Conflict {
  key : String
  column : String?
  reason : String
  base : Array[String]?
  left : Array[String]?
  right : Array[String]?
}

///|
#derive(@json.ToJson)
priv struct Report {
  status : String
  csv : String?
  error : String?
  conflicts : Array[Conflict]
}

///|
fn reconcile(b : Table, l : Table, r : Table) -> Report {
  let seen : Map[String, Bool] = Map([])
  let rows = [b.header]
  let conflicts : Array[Conflict] = []
  for order in [b.order, l.order, r.order] {
    for key in order {
      if seen.contains(key) {
        continue
      }
      seen[key] = true
      let base = b.rows.get(key)
      let left = l.rows.get(key)
      let right = r.rows.get(key)
      let choice = if left == right {
        left
      } else if left == base {
        right
      } else if right == base {
        left
      } else {
        match (base, left, right) {
          (Some(old), Some(a), Some(z)) => {
            let row = old.copy()
            for i, col in b.header {
              if a[i] == z[i] || z[i] == old[i] {
                row[i] = a[i]
              } else if a[i] == old[i] {
                row[i] = z[i]
              } else {
                conflicts.push({
                  key,
                  column: Some(col),
                  reason: "cell-edit",
                  base: Some([old[i]]),
                  left: Some([a[i]]),
                  right: Some([z[i]]),
                })
              }
            }
            Some(row)
          }
          _ => {
            let reason = if base is None { "add/add" } else { "delete/edit" }
            conflicts.push({ key, column: None, reason, base, left, right, })
            None
          }
        }
      }
      if choice is Some(row) {
        rows.push(row)
      }
    }
  }
  if conflicts.is_empty() {
    { status: "merged", csv: Some(encode_csv(rows)), error: None, conflicts, }
  } else {
    { status: "conflict", csv: None, error: None, conflicts, }
  }
}

///|
fn invalid(side : String, reason : String) -> Report {
  {
    status: "invalid",
    csv: None,
    error: Some(side + ": " + reason),
    conflicts: [],
  }
}

///|
fn merge_report(
  base : String,
  left : String,
  right : String,
  key : String,
) -> Report {
  let b = match load_table(base, key, None) {
    Ok(t) => t
    Err(e) => return invalid("base", e)
  }
  let l = match load_table(left, key, Some(b.header)) {
    Ok(t) => t
    Err(e) => return invalid("left", e)
  }
  let r = match load_table(right, key, Some(b.header)) {
    Ok(t) => t
    Err(e) => return invalid("right", e)
  }
  reconcile(b, l, r)
}

///|
pub fn merge_csv(
  base : String,
  left : String,
  right : String,
  key : String,
) -> String {
  @json.ToJson::to_json(merge_report(base, left, right, key)).stringify()
}

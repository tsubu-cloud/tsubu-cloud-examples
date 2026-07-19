///|
pub fn handler(_request : @types.Request) -> @types.Response {
  let body = match @postgres.query("select 1", []) {
    Ok(row_set) => "rows: \{row_set.rows.length()}"
    Err(_) => "query failed"
  }
  @logger.log(body)
  @types.Response::{ status: 200, headers: [], body }
}
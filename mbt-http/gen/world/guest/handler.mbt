///|
pub fn handler(_request : @types.Request) -> @types.Response {
  let response = @fetcher.fetch(@fetcher_types.Request::{
    method_: "GET",
    headers: [],
    body: "",
  })
  @logger.log(response.body)
  // fetch-status`0` means the outbound fetch itself failed (see
  // src/hosts/fetch.zig); that's not a valid HTTP status to relay to the
  // client, so surface it as a Bad Gateway instead.
  if response.status == 0 {
    @types.Response::{ status: 502, headers: [], body: "upstream fetch failed" }
  } else {
    @types.Response::{
      status: response.status,
      headers: response.headers,
      body: response.body,
    }
  }
}
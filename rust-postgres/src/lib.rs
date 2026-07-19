mod guest;
mod handlers;
mod models;

use guest::{Guest, Request, Response};

struct Handler;

impl Guest for Handler {
    fn handler(request: Request) -> Response {
        let request = tsubu_router::Request {
            url: request.url,
            method: request.method,
            headers: request.headers,
            body: request.body,
        };
        let response = handlers::router().handle(request);
        Response {
            status: response.status,
            headers: response.headers,
            body: response.body,
        }
    }
}

guest::export!(Handler with_types_in guest);

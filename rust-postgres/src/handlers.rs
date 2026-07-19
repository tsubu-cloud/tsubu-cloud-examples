use crate::guest::tsubu_cloud::postgres::postgres;
use crate::guest::tsubu_cloud::postgres::types::ParameterValue;
use crate::models::User;
use tsubu_router::{Context, Response, Router};

fn list_users(_ctx: &Context) -> Response {
    let Ok(row_set) = postgres::query("select id, email, created_at from users", &[]) else {
        return Response {
            status: 500,
            headers: vec![],
            body: "failed to query".to_string(),
        };
    };
    let users: Result<Vec<User>, String> = row_set
        .rows
        .iter()
        .map(|row| User::try_from(row.as_slice()))
        .collect();

    let Ok(body) = users.and_then(|users| serde_json::to_string(&users).map_err(|e| e.to_string()))
    else {
        return Response {
            status: 500,
            headers: vec![],
            body: "failed to serialize".to_string(),
        };
    };

    Response {
        status: 200,
        headers: vec![("content-type".to_string(), "application/json".to_string())],
        body,
    }
}

fn get_user(ctx: &Context) -> Response {
    let id = ctx.params.get("id").expect("route requires :id param");

    let Ok(row_set) = postgres::query(
        "select id, email, created_at from users where id = $1",
        &[ParameterValue::Str(id.clone())],
    ) else {
        return Response {
            status: 500,
            headers: vec![],
            body: "failed to query".to_string(),
        };
    };

    let Some(row) = row_set.rows.first() else {
        return Response {
            status: 404,
            headers: vec![],
            body: "not found".to_string(),
        };
    };

    let Ok(user) = User::try_from(row.as_slice()) else {
        return Response {
            status: 500,
            headers: vec![],
            body: "failed to parse row".to_string(),
        };
    };

    let Ok(body) = serde_json::to_string(&user) else {
        return Response {
            status: 500,
            headers: vec![],
            body: "failed to serialize".to_string(),
        };
    };

    Response {
        status: 200,
        headers: vec![("content-type".to_string(), "application/json".to_string())],
        body,
    }
}

pub fn router() -> Router {
    Router::new()
        .get("/users", list_users)
        .get("/users/:id", get_user)
}

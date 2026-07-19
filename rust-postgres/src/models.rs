use crate::guest::tsubu_cloud::postgres::types::DbValue;
use serde::Serialize;

#[derive(Serialize)]
pub struct User {
    pub id: String,
    pub email: String,
    pub created_at: i64,
}

impl TryFrom<&[DbValue]> for User {
    type Error = String;

    fn try_from(row: &[DbValue]) -> Result<Self, Self::Error> {
        let [id, email, created_at] = row else {
            return Err(format!("expected 3 columns, got {}", row.len()));
        };
        Ok(User {
            id: match id {
                DbValue::Uuid(s) => s.clone(),
                other => return Err(format!("unexpected type for id: {other:?}")),
            },
            email: match email {
                DbValue::Str(s) => s.clone(),
                other => return Err(format!("unexpected type for email: {other:?}")),
            },
            created_at: match created_at {
                DbValue::Timestamp(t) => *t,
                other => return Err(format!("unexpected type for created_at: {other:?}")),
            },
        })
    }
}

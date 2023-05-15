use actix_web::{HttpRequest, HttpResponse, web};
use sqlx::PgPool;
use uuid::Uuid;
use chrono::Utc;

#[derive(serde::Deserialize)]
pub struct FormData {
    email: String,
    name: String,
}

#[tracing::instrument(
    name = "Adding a new subscriber",
    skip(form, connection_pool),
    fields(
        email = %form.email,
        name = %form.name
    )
)]
pub async fn subscribe(
    _req: HttpRequest,
    form: web::Form<FormData>,
    connection_pool: web::Data<PgPool>
) -> HttpResponse {

    match insert_subscriber(&form, &connection_pool).await {
        Ok(_) => {
            tracing::info!("New subscriber details have been saved in the database.");
            HttpResponse::Ok().finish()
        },
        Err(e) => {
            tracing::error!("Failed to save subscriber into database {:?}", e);
            HttpResponse::InternalServerError().finish()
        }
    }

}

#[tracing::instrument(
    name = "Saving new subscriber details in the database",
    skip(form, connection_pool)
)]
async fn insert_subscriber(
    form: &FormData,
    connection_pool: &PgPool,
) -> Result<(), sqlx::Error> {
    sqlx::query!(r#"
            INSERT INTO subscriptions (id, email, name, subscribed_at)
            VALUES ($1, $2, $3, $4)
        "#,
        Uuid::new_v4(),
        form.email,
        form.name,
        Utc::now()
    )
        .execute(connection_pool)
        .await
        .map_err(|e| {
            tracing::error!("Failed to execute query {:?}", e);
            e
        })?;
    Ok(())
}
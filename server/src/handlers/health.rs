use actix_web::{HttpResponse, Responder};
use serde::Serialize;

#[derive(Serialize)]
struct HealthResponse {
    status: String,
    version: String,
}

#[derive(Serialize)]
struct ReadinessResponse {
    status: String,
    services: ServiceStatus,
}

#[derive(Serialize)]
struct ServiceStatus {
    storage: String,
    processor: String,
}

pub async fn health_check() -> impl Responder {
    HttpResponse::Ok().json(HealthResponse {
        status: "healthy".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
    })
}

pub async fn readiness_check() -> impl Responder {
    // In a real implementation, check actual service status
    HttpResponse::Ok().json(ReadinessResponse {
        status: "ready".to_string(),
        services: ServiceStatus {
            storage: "ok".to_string(),
            processor: "ok".to_string(),
        },
    })
}

use actix_cors::Cors;
use actix_web::{middleware, web, App, HttpServer};
use std::sync::Arc;
use tracing::info;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod handlers;
mod processor;
mod storage;

use handlers::{health, packages, setup, upload};
use storage::Storage;

pub struct AppState {
    pub storage: Arc<Storage>,
    pub api_keys: Vec<String>,
    pub data_dir: String,
    pub gpg_dir: String,
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration from environment
    let data_dir = std::env::var("REPO_DATA_DIR").unwrap_or_else(|_| "/data/packages".to_string());
    let gpg_dir = std::env::var("REPO_GPG_DIR").unwrap_or_else(|_| "/data/gpg".to_string());
    let api_port: u16 = std::env::var("REPO_API_PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse()
        .unwrap_or(8080);

    // Parse API keys
    let api_keys: Vec<String> = std::env::var("API_KEYS")
        .unwrap_or_else(|_| "default-change-me".to_string())
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    // Initialize storage
    let s3_enabled = std::env::var("S3_ENABLED")
        .unwrap_or_else(|_| "false".to_string())
        .parse::<bool>()
        .unwrap_or(false);

    let storage = if s3_enabled {
        info!("Initializing S3 storage backend");
        Storage::new_s3(
            std::env::var("S3_ENDPOINT").ok(),
            std::env::var("S3_BUCKET").unwrap_or_else(|_| "packages".to_string()),
            std::env::var("S3_REGION").unwrap_or_else(|_| "us-east-1".to_string()),
        )
        .await
    } else {
        info!("Using local storage backend at {}", data_dir);
        Storage::new_local(data_dir.clone())
    };

    let app_state = web::Data::new(AppState {
        storage: Arc::new(storage),
        api_keys,
        data_dir,
        gpg_dir,
    });

    info!("Starting Package Repository API server on port {}", api_port);

    HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        App::new()
            .app_data(app_state.clone())
            .wrap(cors)
            .wrap(middleware::Logger::default())
            .wrap(middleware::Compress::default())
            // Health endpoints
            .route("/health", web::get().to(health::health_check))
            .route("/ready", web::get().to(health::readiness_check))
            // Setup scripts (one-liner install)
            .route("/setup/apt", web::get().to(setup::apt_setup))
            .route("/setup/deb", web::get().to(setup::apt_setup))
            .route("/setup/rpm", web::get().to(setup::rpm_setup))
            .route("/setup/yum", web::get().to(setup::rpm_setup))
            .route("/setup/dnf", web::get().to(setup::rpm_setup))
            .route("/setup/arch", web::get().to(setup::arch_setup))
            .route("/setup/pacman", web::get().to(setup::arch_setup))
            .route("/setup/alpine", web::get().to(setup::alpine_setup))
            .route("/setup/apk", web::get().to(setup::alpine_setup))
            // API v1 routes
            .service(
                web::scope("/api/v1")
                    // Upload endpoints
                    .route("/upload/{pkg_type}", web::post().to(upload::upload_package))
                    // Package management
                    .route("/packages", web::get().to(packages::list_packages))
                    .route(
                        "/packages/{pkg_type}",
                        web::get().to(packages::list_packages_by_type),
                    )
                    .route(
                        "/packages/{pkg_type}/{name}",
                        web::delete().to(packages::delete_package),
                    )
                    // Repository management
                    .route("/repos/{pkg_type}/rebuild", web::post().to(packages::rebuild_repo)),
            )
    })
    .bind(("0.0.0.0", api_port))?
    .run()
    .await
}

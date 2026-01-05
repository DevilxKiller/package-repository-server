use aws_config::BehaviorVersion;
use aws_sdk_s3::Client as S3Client;
use std::path::{Path, PathBuf};
use thiserror::Error;
use tokio::fs;
use tracing::{debug, error, info};

#[derive(Error, Debug)]
pub enum StorageError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("S3 error: {0}")]
    S3(String),

    #[error("File not found: {0}")]
    NotFound(String),
}

pub enum StorageBackend {
    Local { base_path: PathBuf },
    S3 { client: S3Client, bucket: String },
}

pub struct Storage {
    backend: StorageBackend,
}

impl Storage {
    pub fn new_local(base_path: String) -> Self {
        Storage {
            backend: StorageBackend::Local {
                base_path: PathBuf::from(base_path),
            },
        }
    }

    pub async fn new_s3(endpoint: Option<String>, bucket: String, region: String) -> Self {
        let mut config_loader = aws_config::defaults(BehaviorVersion::latest()).region(
            aws_sdk_s3::config::Region::new(region),
        );

        // Use custom endpoint if provided (for MinIO, DigitalOcean Spaces, etc.)
        if let Some(ep) = endpoint {
            config_loader = config_loader.endpoint_url(ep);
        }

        let config = config_loader.load().await;
        let client = S3Client::new(&config);

        Storage {
            backend: StorageBackend::S3 { client, bucket },
        }
    }

    pub async fn write(&self, path: &str, data: &[u8]) -> Result<(), StorageError> {
        match &self.backend {
            StorageBackend::Local { base_path } => {
                let full_path = base_path.join(path);

                // Ensure parent directory exists
                if let Some(parent) = full_path.parent() {
                    fs::create_dir_all(parent).await?;
                }

                fs::write(&full_path, data).await?;
                debug!("Wrote {} bytes to {:?}", data.len(), full_path);
                Ok(())
            }
            StorageBackend::S3 { client, bucket } => {
                client
                    .put_object()
                    .bucket(bucket)
                    .key(path)
                    .body(data.to_vec().into())
                    .send()
                    .await
                    .map_err(|e| StorageError::S3(e.to_string()))?;

                debug!("Wrote {} bytes to s3://{}/{}", data.len(), bucket, path);
                Ok(())
            }
        }
    }

    pub async fn read(&self, path: &str) -> Result<Vec<u8>, StorageError> {
        match &self.backend {
            StorageBackend::Local { base_path } => {
                let full_path = base_path.join(path);

                if !full_path.exists() {
                    return Err(StorageError::NotFound(path.to_string()));
                }

                let data = fs::read(&full_path).await?;
                debug!("Read {} bytes from {:?}", data.len(), full_path);
                Ok(data)
            }
            StorageBackend::S3 { client, bucket } => {
                let response = client
                    .get_object()
                    .bucket(bucket)
                    .key(path)
                    .send()
                    .await
                    .map_err(|e| StorageError::S3(e.to_string()))?;

                let data = response
                    .body
                    .collect()
                    .await
                    .map_err(|e| StorageError::S3(e.to_string()))?
                    .into_bytes()
                    .to_vec();

                debug!("Read {} bytes from s3://{}/{}", data.len(), bucket, path);
                Ok(data)
            }
        }
    }

    pub async fn delete(&self, path: &str) -> Result<(), StorageError> {
        match &self.backend {
            StorageBackend::Local { base_path } => {
                let full_path = base_path.join(path);

                if full_path.exists() {
                    if full_path.is_dir() {
                        fs::remove_dir_all(&full_path).await?;
                    } else {
                        fs::remove_file(&full_path).await?;
                    }
                    debug!("Deleted {:?}", full_path);
                }
                Ok(())
            }
            StorageBackend::S3 { client, bucket } => {
                client
                    .delete_object()
                    .bucket(bucket)
                    .key(path)
                    .send()
                    .await
                    .map_err(|e| StorageError::S3(e.to_string()))?;

                debug!("Deleted s3://{}/{}", bucket, path);
                Ok(())
            }
        }
    }

    pub async fn exists(&self, path: &str) -> bool {
        match &self.backend {
            StorageBackend::Local { base_path } => base_path.join(path).exists(),
            StorageBackend::S3 { client, bucket } => client
                .head_object()
                .bucket(bucket)
                .key(path)
                .send()
                .await
                .is_ok(),
        }
    }

    pub async fn list(&self, prefix: &str) -> Result<Vec<String>, StorageError> {
        match &self.backend {
            StorageBackend::Local { base_path } => {
                let full_path = base_path.join(prefix);
                let mut files = Vec::new();

                if full_path.exists() && full_path.is_dir() {
                    collect_files(&full_path, base_path, &mut files)?;
                }

                Ok(files)
            }
            StorageBackend::S3 { client, bucket } => {
                let response = client
                    .list_objects_v2()
                    .bucket(bucket)
                    .prefix(prefix)
                    .send()
                    .await
                    .map_err(|e| StorageError::S3(e.to_string()))?;

                let files = response
                    .contents()
                    .iter()
                    .filter_map(|obj| obj.key().map(String::from))
                    .collect();

                Ok(files)
            }
        }
    }
}

fn collect_files(
    dir: &Path,
    base: &Path,
    files: &mut Vec<String>,
) -> Result<(), std::io::Error> {
    for entry in std::fs::read_dir(dir)? {
        let entry = entry?;
        let path = entry.path();

        if path.is_dir() {
            collect_files(&path, base, files)?;
        } else {
            if let Ok(relative) = path.strip_prefix(base) {
                files.push(relative.to_string_lossy().to_string());
            }
        }
    }
    Ok(())
}

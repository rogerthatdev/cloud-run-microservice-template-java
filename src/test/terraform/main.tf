variable "project_id" {
  type = string
}

resource "google_service_account" "service_account" {
    project = var.project_id
  account_id   = "build-scheduler"
  display_name = "build scheduler"
}

resource "google_project_iam_member" "project" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_cloudbuild_trigger" "default" {
  name    = "buildpack-failer"
  project = var.project_id
  source_to_build {
    uri       = "https://github.com/rogerthatdev/cloud-run-microservice-template-java"
    ref       = "refs/heads/main"
    repo_type = "GITHUB"
  }

  git_file_source {
    path      = "src/test/resources/advance.cloudbuild.yaml"
    uri       = "https://github.com/rogerthatdev/cloud-run-microservice-template-java"
    revision  = "refs/heads/main"
    repo_type = "GITHUB"
  }

}

resource "google_cloud_scheduler_job" "main" {
    project = var.project_id
    region = "us-central1"
  name        = "buildpack-failer"
  description = "test job"
  schedule    = "*/10 * * * *"
  time_zone        = "America/Los_Angeles"

  http_target {
    http_method = "POST"
    uri = "https://cloudbuild.googleapis.com/v1/projects/${google_cloudbuild_trigger.default.project}/locations/${google_cloudbuild_trigger.default.location}/triggers/${google_cloudbuild_trigger.default.trigger_id}:run"
   

    oauth_token {
      scope = "https://www.googleapis.com/auth/cloud-platform"
      service_account_email = google_service_account.service_account.email
    }
  }

  

retry_config {
        max_backoff_duration = "3600s" 
        max_doublings        = 5 
        max_retry_duration   = "0s" 
        min_backoff_duration = "5s" 
        retry_count          = 0 
        }
}
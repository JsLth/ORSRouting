skip_if_docker_unavailable <- function() {
  skip_if_not(docker_installed() && has_docker_access(), "docker unavailable")
}

skip_docker <- function() {
  skip_if_not(isTRUE(as.logical(Sys.getenv("TEST_DOCKER"))))
}

is_mock_test <- function() {
  !nzchar(Sys.getenv("REAL_REQUESTS"))
}

#' Start a local ORS instance using `ors_instance`.
#'
#' @param ... Arguments to ors_instance
#' @param complete If dry = TRUE, whether to start a complete instance
#' including extract and config
#' @noRd
local_ors_instance <- function(dir = tempdir(),
                               ...,
                               dry = TRUE,
                               complete = FALSE,
                               .local_envir = parent.frame()) {
  ors <- ORSLocal$new(dir = dir, dry = dry, ...)

  if (isTRUE(dry) && complete) {
    create_dry_files(ors)
    ors$update("self")
  }

  withr::defer(ors$purge(), envir = .local_envir)
  invisible(ors)
}

with_ors_instance <- function(code,
                              dir = tempdir(),
                              ...,
                              verbose = TRUE,
                              dry = TRUE,
                              complete = FALSE,
                              .local_envir = parent.frame()) {
  ors <- ORSLocal$new(dir = dir, dry = dry, verbose = verbose, prompts = FALSE, ...)

  if (isTRUE(dry) && complete) {
    create_dry_files(ors)
    ors$update("self")
  }

  env <- new.env(parent = .local_envir)
  assign("ors", ors, envir = env)

  withr::defer(capture.output(ors$purge(), type = "message"), envir = env)
  res <- force(eval(substitute(code), envir = env))
  withr::deferred_run(envir = env)
  res
}

create_dry_files <- function(ors) {
  data_dir <- file.path(ors$paths$top, "docker", "data")
  if (dir.exists(data_dir)) stop("Data dir somehow already exists")
  dir.create(data_dir, recursive = TRUE)
  ors$set_extract(
    file = system.file("setup/monaco.pbf", package = "rors"),
    do_use = FALSE
  )

  conf_dir <- file.path(ors$paths$top, "docker", "conf")
  if (dir.exists(conf_dir)) stop("Conf dir somehow already exists")
  dir.create(conf_dir, recursive = TRUE)
  yaml::write_yaml(
    list(
      ors = list(
        engine = list(
          source_file = "ors-api/src/test/files/heidelberg.osm.gz",
          profiles = list(car = list(enabled = TRUE))
        )
      )
    ),
    file = file.path(conf_dir, "ors-config.yml")
  )
}

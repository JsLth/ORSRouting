skip_if_offline("github.com")

ors <- local_ors_instance(
  verbose = FALSE,
  dry = TRUE,
  version = "7c77ae5"
)

test_that("setup is created properly", {
  expect_true(file.exists(ors$paths$compose))
})

test_that("instance is mounted", {
  expect_true(any_mounted())
  expect_no_error(check_instance())
  expect_identical(get_id(), "ors-app")
})

test_that("compose is parsed correctly", {
  expect_s3_class(ors$compose, "ors_settings")
  expect_s3_class(ors$compose$parsed, "ors_compose_parsed")
  expect_no_error(capture_output(print(ors$compose)))
  expect_s3_class(ors$compose$ports, "data.frame")
  expect_true(all(vapply(ors$compose$ports, is.character, logical(1))))
  expect_type(unlist(ors$compose$memory), "double")
  expect_type(ors$compose$name, "character")
  expect_type(ors$compose$image, "character")
  expect_true(is_true_or_false(ors$compose$graph_building))
})

test_that("paths are parsed correctly", {
  expect_true(file.exists(ors$paths$compose))
  expect_true(dir.exists(ors$paths$top))
  expect_null(ors$paths$config)
  expect_null(ors$paths$extract)
  expect_output(print(ors$paths), "<- compose", fixed = TRUE)
})

test_that("writing works", {
  og <- readLines(ors$paths$compose, warn = FALSE)
  og <- gsub("\\s*#.+$", "", og) # remove comments
  og <- og[nchar(og) > 0]
  ors$update()
  new <- readLines(ors$paths$compose, warn = FALSE)
  expect_true(identical(og, new))
})

expect_error(
  ors$set_extract(file = system.file("setup/monaco.pbf", package = "rors"))
)

create_dry_files(ors)
ors$update("self")

test_that("extract is parsed correctly", {
  expect_identical(ors$extract$name, "monaco.pbf")
  expect_type(ors$extract$size, "double")
  expect_output(print(ors$paths), "<- extract", fixed = TRUE)
})

test_that("config is parsed correctly", {
  expect_s3_class(ors$config, "ors_config")
  expect_s3_class(ors$config$parsed, "ors_config_parsed")
  expect_named(ors$config$profiles)
  expect_output(print(ors$paths), "<- config", fixed = TRUE)
})

test_that("numeric version is re-used", {
  skip("Skipping until later ORS release")

  with_ors_instance(
    {
      expect_identical(ors$version, "8.0.0")
      expect_identical(ors$compose$version, "8.0.0")
    },
    version = "8.0.0"
  )
})

test_that("version errors are informative", {
  expect_error(
    with_ors_instance({}, version = "notaversion"),
    regexp = "ORS version/commit",
    fixed = TRUE
  )
})

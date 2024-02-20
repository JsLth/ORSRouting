skip_if_offline("openrouteservice.org")

test_that("public api works", {
  expect_warning(ORSRemote$new(server = "pub", token = "notactuallyatoken"))
  ors <- ors_instance(server = "pub")
  withr::local_envvar(ORS_TOKEN = "notactuallyatoken")
  withr::local_seed(1)

  expect_true(is_ors_api(ors$url))
  expect_type(ors$get_status(), "character")
  expect_true(ors$is_ready())
  expect_true(ors$token)

  # test global sampling
  sample <- ors_sample(2)

  expect_warning(ors_pairwise(sample[1], sample[2]))
  cond <- last_ors_conditions()
  expect_match(cond[[1]]$conditions, "Access to this API has been disallowed")
})
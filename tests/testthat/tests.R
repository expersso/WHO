dataset <- "WHOSIS_000001"

test_that("get_data returns a data frame with positive length", {
  life_exp <- get_data(dataset)

  expect_equal(class(life_exp), c("tbl_df", "tbl", "data.frame"))
  expect_true(nrow(life_exp) > 0)
})

test_that("get_codes returns a data frame with positive length", {
  codes <- get_codes()
  expect_equal(class(codes), c("tbl_df", "data.frame"))
  expect_true(nrow(codes) > 0)
})

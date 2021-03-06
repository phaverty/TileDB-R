library(testthat)
library(tiledb)
context("tiledb::libtiledb")

test_that("version is valid", {
  ver <- libtiledb_version()
  expect_equal(length(ver), 3)
  expect_equal(ver[1], c(major = 1))
  expect_gte(ver[2], c(minor = 0))
  expect_gte(ver[3], c(patch = 0))
})

test_that("default libtiledb_config constructor", {
  config <- libtiledb_config()
  config <- libtiledb_config_set(config, "foo", "10")
  expect_equal(libtiledb_config_get(config, "foo"), c("foo" = "10"))
})

test_that("construct libtiledb_config with vector of parameters", {
  params = c("foo" = "bar")
  config <- libtiledb_config(params)
  expect_equal(libtiledb_config_get(config, "foo"), c("foo" = "bar"))
})

test_that("libtiledb_config_get throws an error if paramter does not exist", {
  config <- libtiledb_config()
  expect_equal(unname(libtiledb_config_get(config, "don't exist")), NA_character_)
})

test_that("construct libtiledb_config with an empty vector of paramters", {
  params = c()
  default_config <- libtiledb_config()
  params_config <- libtiledb_config(params)
  expect_equal(
    libtiledb_config_get(default_config, "sm.tile_cache_size"),
    libtiledb_config_get(params_config, "sm.tile_cache_size")
  )
})

test_that("tiledb_config can be converted to an R vector", {
  config <- libtiledb_config()
  config_vec <- libtiledb_config_vector(config)
  expect_is(config_vec, "character")
  check <- c()
  for (n in names(config_vec)) {
    expect_equal(libtiledb_config_get(config, n), config_vec[n])
  }
})

test_that("can create a libtiledb_ctx", {
  ctx <- libtiledb_ctx()
  expect_is(ctx, "externalptr")
})

test_that("default libtiledb_ctx config is the default config", {
  ctx <- libtiledb_ctx()
  ctx_config <- libtiledb_ctx_config(ctx)
  default_config <- libtiledb_config()
  expect_equal(libtiledb_config_vector(ctx_config),
               libtiledb_config_vector(default_config))
})

test_that("libtiledb_ctx with config", {
  config <- libtiledb_config(c(foo = "bar"))
  ctx <- libtiledb_ctx(config)
  expect_equal(libtiledb_config_get(libtiledb_ctx_config(ctx), "foo"),
               c(foo = "bar"))
})

test_that("libtiledb_ctx fs support", {
  ctx <- libtiledb_ctx()
  expect_true(libtiledb_ctx_is_supported_fs(ctx, "file"))
  expect_is(libtiledb_ctx_is_supported_fs(ctx, "s3"), "logical")
  expect_is(libtiledb_ctx_is_supported_fs(ctx, "hdfs"), "logical")
  expect_error(libtiledb_ctx_is_supported_fs(ctx, "should error"))
})

test_that("basic int32 libtiledb_dim constructor works", {
  ctx <- libtiledb_ctx()
  dim <- libtiledb_dim(ctx, "d1", "INT32", c(1L, 100L), 10L)
  expect_is(dim, "externalptr")
})

test_that("basic float64 libtiledb_dim constructor works", {
  ctx <- libtiledb_ctx()
  dim <- libtiledb_dim(ctx, "d1", "FLOAT64", c(1.0, 100.0), 10.0)
  expect_is(dim, "externalptr")
})

test_that("basic libtiledb_domain constructor works", {
  ctx <- libtiledb_ctx()
  d1 <- libtiledb_dim(ctx, "d1", "INT32", c(1L, 100L), 10L)
  d2 <- libtiledb_dim(ctx, "d2", "INT32", c(1L, 100L), 10L)
  dom <- libtiledb_domain(ctx, c(d1, d2))
  expect_is(dom, "externalptr")
})

test_that("libtiledb_domain throws an error when dimensions are different dtypes", {
  ctx <- libtiledb_ctx()
  d1 <- libtiledb_dim(ctx, "d1", "INT32", c(1L, 100L), 10L)
  d2 <- libtiledb_dim(ctx, "d2", "FLOAT64", c(1, 100), 10)
  expect_error(libtiledb_domain(ctx, c(d1, d2)))
})

test_that("basic integer libtiledb_attr constructor works", {
  ctx <- libtiledb_ctx()
  filter <- libtiledb_filter(ctx, "NONE")
  filter_list <- libtiledb_filter_list(ctx, c(filter))
  attr <- libtiledb_attr(ctx, "a1", "INT32", filter_list, 1)
  expect_is(attr, "externalptr")
})

test_that("basic float64 libtiledb_attr constructor works", {
  ctx <- libtiledb_ctx()
  filter <- libtiledb_filter(ctx, "NONE")
  filter_list <- libtiledb_filter_list(ctx, c(filter))
  attr <- libtiledb_attr(ctx, "a1", "FLOAT64", filter_list, 1)
  expect_is(attr, "externalptr")
})

test_that("basic libtiledb_array_schema constructor works", {
  ctx <- libtiledb_ctx()
  dim <- libtiledb_dim(ctx, "d1", "INT32", c(1L, 3L), 3L)
  dom <- libtiledb_domain(ctx, c(dim))
  filter <- libtiledb_filter(ctx, "GZIP")
  libtiledb_filter_set_option(filter, "COMPRESSION_LEVEL", 5)
  filter_list <- libtiledb_filter_list(ctx, c(filter))
  att <- libtiledb_attr(ctx, "a1", "FLOAT64", filter_list, 1)
  sch <- libtiledb_array_schema(ctx, dom, c(att), cell_order = "COL_MAJOR", tile_order = "COL_MAJOR", sparse = FALSE)
  expect_is(sch, "externalptr")
})

test_that("basic dense vector libtiledb_array creation works", {
  tmp <- tempdir()
  setup({
   if (dir.exists(tmp)) {
    unlink(tmp, recursive = TRUE)
   }
   dir.create(tmp)
  })

  ctx <- libtiledb_ctx()
  dim <- libtiledb_dim(ctx, "d1", "INT32", c(1L, 3L), 3L)
  dom <- libtiledb_domain(ctx, c(dim))
  filter <- libtiledb_filter(ctx, "NONE")
  filter_list <- libtiledb_filter_list(ctx, c(filter))
  att <- libtiledb_attr(ctx, "a1", "FLOAT64", filter_list, 1)
  sch <- libtiledb_array_schema(ctx, dom, c(att), cell_order = "COL_MAJOR", tile_order = "COL_MAJOR", sparse = FALSE)
  pth <- paste(tmp, "test_array", sep = "/")
  uri <- libtiledb_array_create(pth, sch)
  expect_true(dir.exists(pth))
  teardown({
    unlink(tmp, recursive = TRUE)
  })
})

test_that("basic dense vector writes / reads works", {
  tmp <- tempdir()
  setup({
   if (dir.exists(tmp)) {
    unlink(tmp, recursive = TRUE)
   }
   dir.create(tmp)
  })

  ctx <- libtiledb_ctx()
  dim <- libtiledb_dim(ctx, "d1", "INT32", c(1L, 3L), 3L)
  dom <- libtiledb_domain(ctx, c(dim))
  filter <- libtiledb_filter(ctx, "NONE")
  filter_list <- libtiledb_filter_list(ctx, c(filter))
  att <- libtiledb_attr(ctx, "a1", "FLOAT64", filter_list, 1)
  sch <- libtiledb_array_schema(ctx, dom, c(att), cell_order = "COL_MAJOR", tile_order = "COL_MAJOR", sparse = FALSE)
  pth <- paste(tmp, "test_dense_read_write", sep = "/")
  uri <- libtiledb_array_create(pth, sch)

  dat <- c(3, 2, 1)
  arr <- libtiledb_array(ctx, uri, "WRITE")
  qry <- libtiledb_query(ctx, arr, "WRITE")
  qry <- libtiledb_query_set_buffer(qry, "a1", dat)
  qry <- libtiledb_query_submit(qry)
  libtiledb_array_close(arr)
  expect_is(qry, "externalptr")

  res <- c(0, 0, 0)
  arr <- libtiledb_array(ctx, uri, "READ")
  qry2 <- libtiledb_query(ctx, arr, "READ")
  qry2 <- libtiledb_query_set_buffer(qry2, "a1", res)
  qry2 <- libtiledb_query_submit(qry2)
  libtiledb_array_close(arr)
  expect_equal(res, dat)
  teardown({
    unlink(tmp, recursive = TRUE)
  })
})

test_that("basic dense vector read subarray works", {
  tmp <- tempdir()
  setup({
   if (dir.exists(tmp)) {
    unlink(tmp, recursive = TRUE)
   }
   dir.create(tmp)
  })
  ctx <- libtiledb_ctx()
  dim <- libtiledb_dim(ctx, "d1", "INT32", c(1L, 3L), 3L)
  dom <- libtiledb_domain(ctx, c(dim))
  filter <- libtiledb_filter(ctx, "NONE")
  filter_list <- libtiledb_filter_list(ctx, c(filter))
  att <- libtiledb_attr(ctx, "a1", "FLOAT64", filter_list, 1)
  sch <- libtiledb_array_schema(ctx, dom, c(att), cell_order = "COL_MAJOR", tile_order = "COL_MAJOR", sparse = FALSE)
  pth <- paste(tmp, "test_dense_read_write", sep = "/")
  uri <- libtiledb_array_create(pth, sch)

  dat <- c(3, 2, 1)
  arr <- libtiledb_array(ctx, uri, "WRITE")
  qry <- libtiledb_query(ctx, arr, "WRITE")
  qry <- libtiledb_query_set_buffer(qry, "a1", dat)
  qry <- libtiledb_query_submit(qry)
  libtiledb_array_close(arr)
  expect_is(qry, "externalptr")

  res <- c(0, 0)
  sub <- c(1L, 2L)
  arr <- libtiledb_array(ctx, uri, "READ")
  qry2 <- libtiledb_query(ctx, arr, "READ")
  qry2 <- libtiledb_query_set_subarray(qry2, sub)
  qry2 <- libtiledb_query_set_buffer(qry2, "a1", res)
  qry2 <- libtiledb_query_submit(qry2)
  libtiledb_array_close(arr)
  expect_equal(res, dat[sub])
  teardown({
    unlink(tmp, recursive = TRUE)
  })
})

test_that("basic tiledb vfs constructor works", {
  ctx <- libtiledb_ctx()
  vfs <- tiledb_vfs(ctx)
  expect_is(vfs, "externalptr")

  config <- libtiledb_config(c(foo="bar"))
  vfs <- tiledb_vfs(ctx, config)
  expect_is(vfs, "externalptr")
})

test_that("basic vfs is_dir, is_file functionality works", {
  tmp <- tempdir()
  setup({
   if (dir.exists(tmp)) {
    unlink(tmp, recursive = TRUE)
   }
   dir.create(tmp)
  })

  ctx <- libtiledb_ctx()
  vfs <- tiledb_vfs(ctx)

  # test dir
  expect_true(tiledb_vfs_is_dir(vfs, tmp))
  expect_false(tiledb_vfs_is_dir(vfs, "i don't exist"))

  test_file_path <- paste("file:/", tmp, "test_file", sep = "/")
  test_file = file(test_file_path, "wb")
  writeChar(c("foo", "bar", "baz"), test_file)
  close(test_file)

  # test file
  expect_true(tiledb_vfs_is_file(vfs, test_file_path))
  expect_false(tiledb_vfs_is_file(vfs, tmp))
  teardown({
    unlink(tmp, recursive = TRUE)
  })
})

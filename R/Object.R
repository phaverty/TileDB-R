check_object_arguments <- function(uri, ctx = tiledb:::ctx) {
  if (!is(ctx, "tiledb_ctx")) {
    stop("argument ctx must a a tiledb_ctx")
  }
  if (missing(uri) || !is.scalar(uri, "character")) {
    stop("argument uri must be a string scalar ")
  }
  return(TRUE)
}

#' Creates a TileDB group object at given uri path
#'
#' @param ctx tiledb_ctx
#' @param uri path which to create group
#' @return uri of created group
#' @examples
#' pth <- tempdir()
#' tiledb_group_create(pth)
#' tiledb_object_type(pth)
#'
#'@export
tiledb_group_create <- function(uri, ctx = tiledb:::ctx) {
  check_object_arguments(uri, ctx)
  return(libtiledb_group_create(ctx@ptr, uri))
}

#' Return the TileDB object type string of a TileDB resource
#'
#' Object types:
#'  - `"ARRAY"`, dense or sparse TileDB array
#'  - `"KEY_VALUE"`, TileDB kv array
#'  - `"GROUP"`, TileDB group
#'  - `"INVALID"``, not a TileDB resource
#'
#' @param ctx tiledb_ctx
#' @param uri path to TileDB resource
#' @return TileDB object type string
#'
#' @export
tiledb_object_type <- function(uri, ctx = tiledb:::ctx) {
  check_object_arguments(uri, ctx)
  return(libtiledb_object_type(ctx@ptr, uri))
}

#' Removes a TileDB resource
#'
#' Raises an error if the uri is invalid, or the uri resource is not a tiledb object
#'
#' @param uri path which to create group
#' @return uri of removed TileDB resource
#' @export
tiledb_object_rm <- function(uri, ctx = tiledb:::ctx) {
  check_object_arguments(uri, ctx)
  return(libtiledb_object_remove(ctx@ptr, uri))
}

#' Move a TileDB resource to new uri path
#'
#' Raises an error if either uri is invalid, or the old uri resource is not a tiledb object
#'
#' @param ctx tiledb_ctx
#' @param old_uri old uri of existing tiledb resource
#' @param new_uri new uri to move tiledb resource
#' @return new uri of moved tiledb resource
#' @export
tiledb_object_mv <- function(old_uri, new_uri, ctx = tiledb:::ctx) {
  if (!is(ctx, "tiledb_ctx")) {
    stop("argument ctx must a a tiledb_ctx")
  }
  if (missing(old_uri) || !is.scalar(old_uri, "character")) {
    stop("argument old_uri must be a string scalar ")
  }
  if (missing(new_uri) || !is.scalar(new_uri, "character")) {
    stop("argument old_uri must be a string scalar ")
  }
  return(libtiledb_object_move(ctx@ptr, old_uri, new_uri))
}

#' List TileDB resources at a given root URI path
#'
#' @param ctx tiledb_ctx
#' @param uri uri path to walk
#' @return a dataframe with object type, object uri string columns
#' @export
tiledb_object_ls <- function(uri, filter = NULL, ctx = tiledb:::ctx) {
  check_object_arguments(uri, ctx)
  return(libtiledb_object_walk(ctx@ptr, uri, order = "PREORDER"))
}

#' Recursively discover TileDB resources at a given root URI path
#'
#' @param ctx tiledb_ctx
#' @param uri root uri path to walk
#' @param order (default "PREORDER") specify "POSTORDER" for "POSTORDER" traversal
#' @return a dataframe with object type, object uri string columns
#' @export
tiledb_object_walk <- function(uri, order = "PREORDER", ctx = tiledb:::ctx) {
  check_object_arguments(uri, ctx)
  return(libtiledb_object_walk(ctx@ptr, uri, order = order, recursive = TRUE))
}

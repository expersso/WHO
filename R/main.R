try_as_numeric <- function(x) {
  tryCatch(as.numeric(x), warning = function(w) x)
}

make_url <- function(code, simple_profile = TRUE) {
  if(simple_profile) {
    simple_profile <- "profile=simple"
  } else {
    simple_profile <- ""
  }

  sprintf("http://apps.who.int/gho/athena/api/GHO/%s?format=json&%s",
          code, simple_profile)
}

get_result <- function(url) {
  response <- httr::GET(url)
  httr::stop_for_status(response)
  httr::content(response, "parsed")
}

parse_data <- function(result) {
  df <- lapply(result$fact, function(row) {
    data.frame(row$dim, value = row$Value, stringsAsFactors = FALSE)
  })

  df <- dplyr::rbind_all(df)
  df <- dplyr::as_data_frame(lapply(df, try_as_numeric))
  names(df) <- tolower(names(df))
  df
}

#' Retrieve Data from the World Health Organization
#'
#' @param code character The code for the time series to be retrieved
#'
#' Time-series codes can be retrieved through the \code{get_codes} function.
#'
#' @return A data frame
#' @export
#'
#' @examples
#' df <- get_data("WHOSIS_000001")
#' head(df)
get_data <- function(code) {
  url <- make_url(code)
  result <- get_result(url)
  parse_data(result)
}

#' Get all codes and metadata for WHO series
#'
#' @param extra logical If \code{TRUE}, downloads additional meta
#' information (e.g. series categories, French and Spanish descriptions
#' (where available), etc).
#'
#' @return A data frame
#' @export
#'
#' @examples
#' codes <- get_codes()
#' str(codes)
get_codes <- function(extra = FALSE) {

  url <- make_url("", FALSE)
  codes <- get_result(url)
  code_list <- codes$dimension[[1]]$code

  df_list <- lapply(code_list, function(row) {

    df_data <- dplyr::as_data_frame(row[c("label", "display", "url")])

    if(extra) {
      # Bind together all attributes for a series into a DF
      row_attr <- lapply(row$attr, function(x) dplyr::as_data_frame(x))
      row_attr <- dplyr::rbind_all(row_attr)

      # Transpose the attributes DF to be able to cbind with data DF
      tryCatch({
        # Get attribute values
        df_attr <- as.data.frame(t(row_attr)[2, , drop = FALSE],
                                 stringsAsFactors = FALSE)

        # Get attribute names
        names(df_attr) <- t(row_attr)[1, ]

        # Return empty DF if no attributes found
      }, error = function(e) df_attr <- dplyr::data_frame(NA))

      # Join data and attributes
      return(cbind(df_data, df_attr))
    }
    df_data
  })

  df <- dplyr::rbind_all(df_list)

  names(df) <- tolower(names(df))

  # Drop degenerate columns with no name
  df[, !grepl("x\\d", names(df))]
}

get_dimensions <- function(result) {
  dims <- result$dimension
  names(dims) <- vapply(dims, "[[", "label", FUN.VALUE = character(1L))
  dims[[1]]
}

# Convert lists of lists of meta data to lists of data frames of meta data
convert_meta_to_df <- function(data_list) {

  dfs <- lapply(data_list, function(meta) {
    data.frame(Filter(function(y) length(y) > 0, meta),
               stringsAsFactors = FALSE)
  })

  df <- dplyr::rbind_all(dfs)
  df[, c("label", "display")]
}

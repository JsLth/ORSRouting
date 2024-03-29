#' Return ORS conditions
#' @description List errors and warnings that were produced in the last
#' call to one of the ORS endpoints.
#' @param last \code{[integer]}
#'
#' Number of error lists that should be returned. \code{last = 2L},
#' for example, returns errors from the last two function calls.
#'
#' @examples
#' \dontrun{
#' library(sf)
#'
#' ors_pairwise(pharma, st_geometry(pharma) + 100)
#' last_ors_conditions()
#' }
#' @export
last_ors_conditions <- function(last = 1L) {
  conditions <- get0("cond", envir = ors_cache)

  if (length(conditions)) {
    assert_that(is.numeric(last), last >= 1)
    last <- min(last, length(conditions))
    conditions <- conditions[seq_len(last)]
    class(conditions) <- "ors_condition_list"
    conditions
  }
}


#' Accepts a result list and handles error and warning codes
#' @param res Response list from `call_ors_directions`
#' @param abort_on_error Whether to abort when an error code is returned
#' @param warn_on_warning Whether to warn when a warning code is returned
#' @noRd
handle_ors_conditions <- function(res,
                                  timestamp,
                                  call,
                                  abort_on_error = FALSE,
                                  warn_on_warning = FALSE) {
  if (is_ors_error(res)) {
    msg <- res$error
    code <- NULL

    if (!is.character(res$error)) {
      msg <- msg$message
      code <- res$error$code
    }

    if (is.null(msg) && !is.null(code)) {
      message <- fill_empty_error_message(code)
    }

    store_condition(code, msg, ts = timestamp, call = call, error = TRUE)

    if (abort_on_error) {
      cli::cli_abort(
        c("ORS encountered the following exception:", error),
        call = NULL
      )
    }
  } else {
    warnings <- get_ors_warnings(res)
    msg <- warnings$message
    code <- warnings$code

    if (length(code) && length(message)) {
      store_condition(code, msg, ts = timestamp, call = call, error = FALSE)

      if (warn_on_warning) {
        w_vec <- cli::cli_vec(
          cond,
          style = list(vec_sep = "\f", vec_last = "\f")
        )
        cli::cli_warn(c("ORS returned {length(w_vec)} warning{?s}:", w_vec))
      }
    }
  }
  NULL
}


store_condition <- function(code, msg, ts, call, error) {
  conds <- ors_cache$cond
  last_cond <- conds[[1]]

  if (identical(last_cond$ts, ts)) {
    last_cond$msg <- c(last_cond$msg, msg)
    last_cond$code <- c(last_cond$code, code)
    conds[[1]] <- last_cond
  } else {
    new_cond <- ors_condition(
      code = code,
      msg = msg,
      ts = ts,
      call = call,
      error = error
    )
    conds <- c(list(new_cond), conds)
  }

  assign("cond", conds, envir = ors_cache)
}


ors_condition <- function(code, msg, ts, call, error) {
  cond <- list(
    code = code,
    msg = msg,
    ts = ts,
    call = call,
    error = error
  )

  class(cond) <- "ors_condition"
  cond
}


handle_missing_directions <- function(.data) {
  route_missing <- is.na(.data)
  conds <- get0("cond", envir = ors_cache)
  if (is.null(conds)) return()
  has_warnings <- conds[[1]]$warn

  # all routes missing
  if (all(route_missing)) {
    cli::cli_warn(c(
      "No routes could be calculated. Is the service correctly configured?",
      cond_tip()
    ))

  # some routes missing
  } else if (any(route_missing)) {
    cond_indices <- cli::cli_vec(
      which(startsWith("Error", conds)),
      style = list(vec_sep = ", ", vec_last = ", ")
    )
    cli::cli_warn(c(
      paste(
        "{length(cond_indices)} route{?s} could not be",
        "calculated and {?was/were} skipped: {cond_indices}"
      ),
      cond_tip()
    ))

  # routes associated with warnings
  } else if (has_warnings) {
    warn_indices <- cli::cli_vec(
      warn_indices,
      style = list(vec_sep = ", ", vec_last = ", ")
    )
    cli::cli_warn(c(
      paste(
        "ORS returned a warning for {length(warn_indices)}",
        "route{?s}: {warn_indices}"
      ),
      cond_tip()
    ))
  }
}


handle_missing_directions_batch <- function(has_cond) {
  if (any(has_cond)) {
    cond_indices <- cli::cli_vec(
      which(has_cond),
      style = list(vec_sep = ", ", vec_last = ", ")
    )

    cli::cli_warn(c(paste(
      "For the following input rows, one or multiple routes",
      "could not be taken into account: {cond_indices}"
    ), cond_tip(sum(has_cond))))
  }
}


cond_tip <- function(last = NULL) {
  callstr <- ifelse(
    is.null(last) || last == 1,
    "rors::last_ors_conditions()",
    sprintf("rors::last_ors_conditions(last = %s)", last)
  )
  callstr <- cli::style_hyperlink(callstr, paste0("rstudio:run:", callstr))
  cli::col_grey(sprintf(
    "Run {.code %s} for a full list of conditions.", callstr
  ))
}


#' Replaces empty error message strings based on their error code
#' @noRd
fill_empty_error_message <- function(code) {
  switch(
    as.character(code),
    `2000` = "Unable to parse JSON request.",
    `2001` = "Required parameter is missing.",
    `2002` = "Invalid parameter format.",
    `2003` = "Invalid parameter value.",
    `2004` = "Parameter value exceeds the maximum allowed limit.",
    `2006` = "Unable to parse the request to the export handler.",
    `2007` = "Unsupported export format.",
    `2008` = "Empty Element.",
    `2009` = "Route could not be found between locations.",
    `2099` = "Unknown internal error.",
    `6000` = "Unable to parse JSON request.",
    `6001` = "Required parameter is missing.",
    `6002` = "Invalid parameter format.",
    `6003` = "Invalid parameter value.",
    `6004` = "Parameter value exceeds the maximum allowed limit.",
    `6006` = "Unable to parse the request to the export handler.",
    `6007` = "Unsupported export format.",
    `6008` = "Empty Element.",
    `6099` = "Unknown internal error.",
    "Unknown error code"
  )
}

assert_that <- function(..., env = parent.frame(), msg = NULL, add = NULL) {
  tryCatch(
    expr = assertthat::assert_that(..., env = env, msg = msg),
    error = function(e) cli::cli_abort(c("x" = e$message, add), call = e$call)
  )
}


is_sf <- function(x, sfc = TRUE) {
  inherits(x, c("sf", if (sfc) "sfc"))
}

is_true_or_false <- function(x) {
  is.logical(x) && length(x) == 1L && !is.na(x)
}

#' Checks whether an sf, sfc or sfg object is of a particular geometry type
#' @param x sf, sfc or sfg object
#' @param types geometry types
#' @param exclusive specifies whether all geometry types in `types` must be
#' present in `x` or if `x` must only contain at least one of these types.
#' @param strict specifies whether all geometries must be of type `type` or if
#' only some geometries need to be of this type.
is_geometry_type <- function(x, types, exclusive = TRUE, strict = TRUE) {
  is_type <- lapply(types, function(gt) sf::st_is(x, gt))
  is_type <- do.call(cbind, is_type)

  if (ncol(is_type) > 1) {
    has_type <- as.logical(colSums(is_type))
  } else {
    has_type <- as.logical(sum(is_type))
  }
  
  if (nrow(is_type) > 1) {
    is_type <- as.logical(rowSums(is_type))
  } else {
    is_type <- as.logical(sum(is_type))
  }
  
  if (exclusive) {
    has_type <- all(has_type)
  } else {
    has_type <- any(has_type)
  }
  
  if (strict) {
    is_type <- all(is_type)
  } else {
    is_type <- any(is_type)
  }
  
  is_type && has_type
}

assertthat::on_failure(is_sf) <- function(call, env) {
  x <- sprintf("{.var %s}", deparse(call$x))
  if (call$sfc) {
    paste(x, "is not an {.cls sf} or {.cls sfc} object.")
  } else {
    paste(x, "is not an {.cls sf} dataframe.")
  }
}

assertthat::on_failure(is_true_or_false) <- function(call, env) {
  x <- sprintf("{.var %s}", deparse(call$x))
  if (is.logical(eval(call$x))) {
    paste(x, "is not {.var TRUE} or {.var FALSE}.")
  } else {
    paste(x, "is not a logical.")
  }
}

assertthat::on_failure(is_geometry_type) <- function(call, env) {
  x <- sprintf("{.var %s}", deparse(call$x))
  given <- sf::st_geometry_type(eval(call$x, env))
  given <- paste0(unique(given), "s")
  given <- paste(given, collapse = "/")
  types <- eval(call$type)
  types <- paste0(types, "s")
  types <- paste(
    paste(utils::head(types, -1), collapse = ", "),
    utils::tail(types, 1),
    sep = " or "
  )
  paste0(x, " must consist of only ", types, ", not ", given)
}

assertthat::on_failure(inherits) <- function(call, env) {
  class <- sprintf("{.cls %s}", eval(call$what, env))
  x <- sprintf("{.var %s}", call$x)
  paste0(x, " does not inherit from class ", class)
}


#' Assert that a condition is TRUE else return an error
#' @param class,len,val,nrow,obj,set,file Conditions to assert
#' @param ... Further informational messages to include in the error
#' @param abort Whether to throw an error or return a logical
#' @param null Whether NULL is allowed.
#' @noRd
assert <- function(x,
                   class = NULL,
                   len = NULL,
                   val = NULL,
                   nrow = NULL,
                   obj = NULL,
                   set = NULL,
                   file = NULL,
                   ...,
                   null = FALSE,
                   abort = TRUE) {
  checks <- list()

  if (!is.null(class)) {
    checks[[1]] <- assert_class(
      x,
      class,
      abort = abort,
      null = null,
      .env = environment(),
      ...
    )
  }

  if (!is.null(len)) {
    if (length(len) == 1) len <- rep(len, 2)
    checks[[2]] <- assert_length(
      x,
      min = len[1],
      max = len[2],
      abort = abort,
      null = null,
      .env = environment(),
      ...
    )
  }

  if (!is.null(val)) {
    if (length(val) == 1) val <- rep(val, 2)
    checks[[3]] <- assert_value(
      x,
      min = val[1],
      max = val[2],
      abort = abort,
      null = null,
      .env = environment(),
      ...
    )
  }

  if (!is.null(nrow) && length(nrow) == 2) {
    if (length(nrow) == 1) nrow <- rep(nrow, 2)
    checks[[4]] <- assert_nrow(
      x,
      min = nrow[1],
      nrow[2],
      abort = abort,
      null = null,
      .env = environment(),
      ...
    )
  }

  if (!is.null(obj)) {
    checks[[5]] <- assert_identical(
      x,
      obj,
      abort = abort,
      null = null,
      .env = environment(),
      ...
    )
  }

  if (!is.null(set)) {
    checks[[6]] <- assert_element(
      x,
      set,
      abort = abort,
      null = null,
      .env = environment(),
      ...
    )
  }
  
  if (!is.null(file)) {
    checks[[7]] <- assert_path(
      x,
      file,
      abort = abort,
      null = null, 
      .env = environment(),
      ...
    )
  }

  do.call(all, checks)
}


assert_class <- function(x,
                         class,
                         abort = TRUE,
                         null = FALSE,
                         .env = NULL,
                         ...) {
  if (is.null(x) && null) return(TRUE)

  afuns <- lapply(class, function(c) {
    get0(paste0("is.", c), ifnotfound = \(obj) inherits(obj, c))
  })

  has_class <- any(vapply(afuns, do.call, list(x), FUN.VALUE = logical(1)))

  if (!has_class) {
    if (!abort) {
      return(FALSE)
    }
    
    if (is.null(.env)) .env <- environment()
    var <- deparse(substitute(x, env = .env))

    cli::cli_div(theme = list(span.cls2 = list(
      before = "<", after = ">", color = "blue",
      vec_sep = ", ", vec_last = " or "
    )))

    cli::cli_abort(c(
      "x" = "{.var {var}} is expected to be of class {.cls2 {class}}.",
      "!" = "Got {.cls {class(x)}} instead.",
      ...
    ))
  } else {
    TRUE
  }
}


assert_length <- function(x,
                          min = 0L,
                          max = Inf,
                          abort = TRUE,
                          null = FALSE,
                          .env = NULL,
                          ...) {
  if (is.null(x) && null) return(TRUE)
  
  if (length(x) > max || length(x) < min) {
    if (!abort) {
      return(FALSE)
    }
    
    if (is.null(.env)) .env <- environment()
    var <- deparse(substitute(x, env = .env))
    if (min == max) {
      cli::cli_abort(c(
        "x" = "{.var {var}} is expected to be of length {.val {min}}",
        "!" = "Got object of length {.val {length(x)}} instead."
      ))
    } else {
      cli::cli_abort(c(
        "x" = paste(
          "{.var {var}} is expected to be between length",
          "{.val {min}} and {.val {max}}."
        ),
        "!" = "Got object of length {.val {length(x)}} instead.",
        ...
      ))
    }
  } else {
    TRUE
  }
}


assert_value <- function(x,
                         min = -Inf,
                         max = Inf,
                         abort = TRUE,
                         null = FALSE,
                         .env = NULL,
                         ...) {
  if (is.null(x) && null) return(TRUE)
  
  if (x > max || x < min) {
    if (!abort) {
      return(FALSE)
    }
    
    if (is.null(.env)) .env <- environment()
    var <- deparse(substitute(x, env = .env))
    if (min == max) {
      cli::cli_abort(c(
        "x" = "{.var {var}} is expected to equal {.val {min}}",
        "!" = "Got value {.val {x}} instead."
      ))
    } else {
      cli::cli_abort(c(
        "x" = paste(
          "{.var {var}} is expected to fall",
          "between {.val {min}} and {.val {max}}"
        ),
        "!" = "Got value {.val {x}} instead.",
        ...
      ))
    }
  } else {
    TRUE
  }
}


assert_nrow <- function(x,
                        min = 0L,
                        max = Inf,
                        abort = TRUE,
                        null = FALSE,
                        .env = NULL,
                        ...) {
  if (is.null(x) && null) return(TRUE)
  
  if (nrow(x) > max || nrow(x) < min) {
    if (!abort) {
      return(FALSE)
    }
    
    if (is.null(.env)) .env <- environment()
    var <- deparse(substitute(x, env = .env))
    if (min == max) {
      cli::cli_abort(c(
        "x" = "{.var {var}} is expected to have {.val {min}} rows.",
        "!" = "Got an object with {.val {nrow(x)}} rows instead."
      ))
    } else {
      cli::cli_abort(c(
        "x" = paste(
          "{.var {var}} is expected to have between",
          "{.val {min}} and {.val {max}} rows."
        ),
        "!" = "Got an object with {.val {nrow(x)}} rows instead.",
        ...
      ))
    }
  } else {
    TRUE
  }
}


assert_identical <- function(x,
                             obj,
                             abort = TRUE,
                             null = FALSE,
                             .env = NULL,
                             ...) {
  if (is.null(x) && null) return(TRUE)
  
  if (!identical(x, obj)) {
    if (!abort) {
      return(FALSE)
    }
    
    if (is.null(.env)) .env <- environment()
    var <- deparse(substitute(x, env = .env))
    obj_var <- deparse(substitute(obj, env = .env))
    cli::cli_abort(c(
      "x" = "{.var {var}} is expected to be identical to {.var {obj_var}}.",
      ...
    ))
  } else {
    TRUE
  }
}


assert_element <- function(x,
                           set,
                           abort = TRUE,
                           null = FALSE,
                           .env = NULL,
                           ...) {
  if (is.null(x) && null) return(TRUE)
  
  if (!is.element(x, set)) {
    if (!abort) {
      return(FALSE)
    }
    
    if (is.null(.env)) .env <- environment()
    var <- deparse(substitute(x, env = .env))
    set_var <- deparse(substitute(set, env = .env))
    cli::cli_abort(c(
      "x" = "{.var {var}} is expected to be an element of {.var {set_var}}",
      ...
    ))
  } else {
    TRUE
  }
}


assert_path <- function(x,
                        file = FALSE,
                        abort = TRUE,
                        null = FALSE,
                        .env = NULL,
                        ...) {
  if (is.null(x) && null) return(TRUE)

  if (is.null(.env)) .env <- environment()
  var <- deparse(substitute(x, env = .env))
  type <- ifelse(file, "file", "dir")
  afun <- match.fun(paste0(type, ".exists"))
  
  if (!afun(x)) {
    if (!file) type <- "directory"
    cli::cli_abort(c(
      "x" = "The {type} {.var {var}} ({.path {x}}) does not exist.", ...
    ))
  } else {
    TRUE
  }
}
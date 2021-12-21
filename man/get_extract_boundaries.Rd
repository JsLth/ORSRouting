% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ors-sample.R
\name{get_extract_boundaries}
\alias{get_extract_boundaries}
\title{Extract boundaries}
\usage{
get_extract_boundaries(force = FALSE)
}
\arguments{
\item{force}{If \code{TRUE}, function must query local host. If
\code{FALSE}, the status will be read from the cache if possible.}
}
\value{
An \code{sfc} object of the currently mounted extract boundaries.
}
\description{
Returns boundary geometries of the currently mounted extract
either from the local host or from a local cache.
}
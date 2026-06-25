#' @keywords internal
"_PACKAGE"

# The following block is used by usethis to automatically manage
# roxygen namespace tags. Modify with care!
## usethis namespace: start
#' @useDynLib RcppMirai, .registration = TRUE
#' @importFrom Rcpp sourceCpp
## usethis namespace: end
NULL

# `.flat` is a collector token interpreted by mirai's `[` method inside
# parallel_bootstrap_mean(), not a real variable. Register it so R CMD check
# does not flag it as an undefined global.
utils::globalVariables(".flat")

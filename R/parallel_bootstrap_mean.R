#' Bootstrap the Mean in Parallel with mirai
#'
#' Distributes a bootstrap of the mean across a pool of `mirai` daemons. Each
#' daemon evaluates the packaged C++ kernel [bootstrap_mean()] on a chunk of the
#' replicates, and the pieces are combined into a single bootstrap distribution.
#' When no daemons are running, the kernel is evaluated once in the current
#' session instead.
#'
#' @param x      A `numeric` vector to resample.
#' @param reps   Total number of bootstrap resamples to draw.
#' @param chunks Number of pieces to split `reps` into, one task per piece.
#'   Defaults to the number of connected daemons.
#'
#' @return
#' A `numeric` vector of length `reps` holding the bootstrap distribution of the
#' mean.
#'
#' @export
#'
#' @details
#' Daemon set up is intentionally left to the caller, in keeping with the design
#' of `mirai`. Start a pool with [mirai::daemons()] before calling this function
#' to run in parallel, and reset it with `mirai::daemons(0)` when finished. The
#' number of connected daemons is read from [mirai::status()].
#'
#' The work is sent to the daemons through the package worker `bootstrap_chunk()`
#' rather than an inline function. Because that worker lives in the package
#' namespace, `mirai` transmits only a reference to it, not a copy of this
#' function's environment, and each daemon loads the package (and its compiled
#' code) to run it. Defining the worker inline would instead capture the whole
#' calling frame and send it to every daemon.
#'
#' When daemons are running, each one draws from its own independent random
#' number stream. Pass a `seed` to [mirai::daemons()] to make those streams
#' reproducible for a fixed number of `chunks`. The in-session fallback draws
#' from the ordinary session stream, so its values will not match the parallel
#' path.
#'
#' @examples
#' x = rnorm(500)
#'
#' # With no daemon pool the kernel runs in the current session.
#' boot = parallel_bootstrap_mean(x, reps = 1000)
#' str(boot)
#'
#' # Set up daemons to draw the resamples in parallel.
#' if (interactive()) {
#'   mirai::daemons(2)
#'   boot = parallel_bootstrap_mean(x, reps = 1e5)
#'   mirai::daemons(0)
#'   quantile(boot, c(0.025, 0.5, 0.975))
#' }
parallel_bootstrap_mean = function(x, reps = 10000L, chunks = NULL) {

  reps = as.integer(reps)

  # mirai leaves daemon set up to the caller. With no connected daemons,
  # evaluate the compiled kernel once in the current session.
  n_daemons = mirai::status()$connections
  if (n_daemons < 1L) {
    return(bootstrap_mean(x, reps))
  }

  # One task per daemon unless the caller asks for a different split.
  if (is.null(chunks)) {
    chunks = n_daemons
  }
  chunks = max(1L, min(as.integer(chunks), reps))

  # Split `reps` as evenly as possible into `chunks` pieces.
  sizes = diff(round(seq(0L, reps, length.out = chunks + 1L)))
  sizes = sizes[sizes > 0L]

  # Distribute the pieces across the daemons. `bootstrap_chunk` is a package
  # function, so only a reference to it travels to each daemon, which then
  # loads the package to reach the compiled kernel.
  mirai::mirai_map(
    sizes,
    bootstrap_chunk,
    .args = list(x = x)
  )[.flat]
}

# Internal worker run on each daemon: draw `reps` bootstrap means of `x`.
# Kept at the top level (its environment is the package namespace) so that
# `mirai` serialises a reference to it instead of a copy of the caller's frame.
bootstrap_chunk = function(reps, x) {
  RcppMirai::bootstrap_mean(x, reps)
}

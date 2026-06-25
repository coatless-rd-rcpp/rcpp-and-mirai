# Bootstrap the Mean in Parallel with mirai

Distributes a bootstrap of the mean across a pool of `mirai` daemons.
Each daemon evaluates the packaged C++ kernel
[`bootstrap_mean()`](https://rd-rcpp.thecoatlessprofessor.com/rcpp-and-mirai/reference/bootstrap_mean.md)
on a chunk of the replicates, and the pieces are combined into a single
bootstrap distribution. When no daemons are running, the kernel is
evaluated once in the current session instead.

## Usage

``` r
parallel_bootstrap_mean(x, reps = 10000L, chunks = NULL)
```

## Arguments

- x:

  A `numeric` vector to resample.

- reps:

  Total number of bootstrap resamples to draw.

- chunks:

  Number of pieces to split `reps` into, one task per piece. Defaults to
  the number of connected daemons.

## Value

A `numeric` vector of length `reps` holding the bootstrap distribution
of the mean.

## Details

Daemon set up is intentionally left to the caller, in keeping with the
design of `mirai`. Start a pool with
[`mirai::daemons()`](https://mirai.r-lib.org/reference/daemons.html)
before calling this function to run in parallel, and reset it with
`mirai::daemons(0)` when finished. The number of connected daemons is
read from
[`mirai::status()`](https://mirai.r-lib.org/reference/status.html).

The work is sent to the daemons through the package worker
`bootstrap_chunk()` rather than an inline function. Because that worker
lives in the package namespace, `mirai` transmits only a reference to
it, not a copy of this function's environment, and each daemon loads the
package (and its compiled code) to run it. Defining the worker inline
would instead capture the whole calling frame and send it to every
daemon.

When daemons are running, each one draws from its own independent random
number stream. Pass a `seed` to
[`mirai::daemons()`](https://mirai.r-lib.org/reference/daemons.html) to
make those streams reproducible for a fixed number of `chunks`. The
in-session fallback draws from the ordinary session stream, so its
values will not match the parallel path.

## Examples

``` r
x = rnorm(500)

# With no daemon pool the kernel runs in the current session.
boot = parallel_bootstrap_mean(x, reps = 1000)
str(boot)
#>  num [1:1000] -0.06243 -0.04264 -0.07245 0.02076 0.00907 ...

# Set up daemons to draw the resamples in parallel.
if (interactive()) {
  mirai::daemons(2)
  boot = parallel_bootstrap_mean(x, reps = 1e5)
  mirai::daemons(0)
  quantile(boot, c(0.025, 0.5, 0.975))
}
```

#include <Rcpp.h>

//' Bootstrap the Mean of a Numeric Vector
//'
//' Draws `reps` bootstrap resamples (sampling with replacement) of `x` and
//' returns the mean of each resample. This is the compute kernel that the
//' package distributes across _mirai_ daemons.
//'
//' @param x    A `numeric` vector to resample.
//' @param reps The number of bootstrap resamples to draw.
//'
//' @return
//' A `numeric` vector of length `reps` holding the bootstrap distribution of
//' the mean.
//'
//' @details
//' The routine uses _R_'s random number generator through `R::unif_rand()`.
//' When the kernel runs on a _mirai_ daemon, each daemon is given its own
//' independent random number stream, so resamples drawn in parallel remain
//' statistically sound.
//'
//' @examples
//' bootstrap_mean(rnorm(100), reps = 10)
//'
//' @export
// [[Rcpp::export]]
Rcpp::NumericVector bootstrap_mean(Rcpp::NumericVector x, int reps) {
  int n = x.size();
  Rcpp::NumericVector out(reps);

  for (int b = 0; b < reps; b++) {
    double sum = 0.0;
    for (int i = 0; i < n; i++) {
      int idx = (int)(R::unif_rand() * n);   // draw an index in [0, n)
      sum += x[idx];
    }
    out[b] = sum / n;
  }

  return out;
}

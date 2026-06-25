# Bootstrap the Mean of a Numeric Vector

Draws `reps` bootstrap resamples (sampling with replacement) of `x` and
returns the mean of each resample. This is the compute kernel that the
package distributes across *mirai* daemons.

## Usage

``` r
bootstrap_mean(x, reps)
```

## Arguments

- x:

  A `numeric` vector to resample.

- reps:

  The number of bootstrap resamples to draw.

## Value

A `numeric` vector of length `reps` holding the bootstrap distribution
of the mean.

## Details

The routine uses *R*'s random number generator through `R::unif_rand()`.
When the kernel runs on a *mirai* daemon, each daemon is given its own
independent random number stream, so resamples drawn in parallel remain
statistically sound.

## Examples

``` r
bootstrap_mean(rnorm(100), reps = 10)
#>  [1]  0.202395127  0.125968586 -0.027877798  0.010542109  0.355036565
#>  [6]  0.038738226 -0.124705057  0.006479518  0.138031685  0.056273694
```

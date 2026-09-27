# Rasch and lognormal response-time building blocks, evaluated on a theta grid.

softplus <- function(x) pmax(x, 0) + log1p(exp(-abs(x)))

# Per-person log-likelihood of Rasch responses at each grid point (N x G).
grid_loglik <- function(idx, b, x, N, grid) {
  out <- matrix(0, N, length(grid))
  if (!length(idx)) return(out)
  eta <- outer(-b, grid, "+")
  r <- rowsum(x * eta - softplus(eta), idx)
  out[as.integer(rownames(r)), ] <- r
  out
}

# Per-person expected score and variance at each grid point (N x G each).
grid_moments <- function(idx, b, N, grid) {
  E <- V <- matrix(0, N, length(grid))
  if (!length(idx)) return(list(E = E, V = V))
  P <- stats::plogis(outer(-b, grid, "+"))
  rows <- as.integer(rownames(rowsum(P[, 1, drop = FALSE], idx)))
  E[rows, ] <- rowsum(P, idx)
  V[rows, ] <- rowsum(P * (1 - P), idx)
  list(E = E, V = V)
}

normalize_rows <- function(M) M / rowSums(M)

# Posterior-predictive z for an observed score S given grid weights W.
predictive_z <- function(W, mom, S) {
  mu <- rowSums(W * mom$E)
  v <- rowSums(W * (mom$V + mom$E^2)) - mu^2
  (S - mu) / sqrt(pmax(v, 1e-12))
}

# Growth transition: W2[n, g2] = sum_g1 W1[n, g1] * N(grid[g2] - grid[g1] - m[n]; 0, sd)
# The kernel depends only on the grid offset d = g2 - g1, so loop over offsets.
# The kernel depends only on the grid offset d = g2 - g1, so loop over offsets.
# It is normalized over offsets, matching the likelihood in rt_fit().
propagate <- function(W1, grid, m, sd) {
  G <- length(grid); h <- grid[2] - grid[1]
  ds <- -(G - 1):(G - 1)
  K <- stats::dnorm(outer(-m, ds * h, "+"), 0, sd)
  K <- K / rowSums(K)
  out <- matrix(0, nrow(W1), G)
  for (k in seq_along(ds)) {
    d <- ds[k]
    g1 <- max(1, 1 - d):min(G, G - d)
    out[, g1 + d] <- out[, g1 + d] + W1[, g1, drop = FALSE] * K[, k]
  }
  normalize_rows(out)
}

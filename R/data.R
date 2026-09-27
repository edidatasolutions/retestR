#' Assemble two-attempt repeater data
#'
#' @param responses Long data frame, one row per person x attempt x item:
#'   `person`, `attempt` (1 or 2), `item`, `x` (0/1), and optionally `rt`
#'   (response time in seconds).
#' @param persons One row per repeater: `person` plus the covariates used by
#'   the growth model (e.g. `days_between`, `remediation`).
#' @param bank Calibrated item bank: `item`, `b` (Rasch difficulty), `exposed`
#'   (TRUE for items that may be compromised, e.g. long-running operational
#'   items; FALSE for new items), and optionally `beta` (lognormal time
#'   intensity, log-seconds).
#' @return An `rt_data` object.
#' @examples
#' bank <- data.frame(item = paste0("Q", 1:20), b = rnorm(20),
#'                    exposed = rep(c(TRUE, FALSE), each = 10))
#' persons <- data.frame(person = c("A", "B"), days_between = c(60, 200),
#'                       remediation = c(0, 1))
#' resp <- data.frame(person = rep(c("A", "B"), each = 20),
#'                    attempt = rep(rep(1:2, each = 10), 2),
#'                    item = c(paste0("Q", c(1:5, 11:15, 6:10, 16:20)),
#'                             paste0("Q", c(6:10, 16:20, 1:5, 11:15))),
#'                    x = rbinom(40, 1, 0.6))
#' str(rt_data(resp, persons, bank)$responses)
#' @details Assumes no item is administered to the same person on both
#'   attempts (legitimate item memory would otherwise look like preknowledge).
#' @export
rt_data <- function(responses, persons, bank) {
  r <- data.frame(person = as.character(responses$person),
                  attempt = as.integer(responses$attempt),
                  item = as.character(responses$item),
                  x = as.integer(responses$x), stringsAsFactors = FALSE)
  if (!is.null(responses$rt)) r$rt <- as.numeric(responses$rt)
  bank <- as.data.frame(bank, stringsAsFactors = FALSE)
  bank$item <- as.character(bank$item)
  persons <- as.data.frame(persons, stringsAsFactors = FALSE)
  persons$person <- as.character(persons$person)

  if (!all(r$attempt %in% 1:2)) stop("`attempt` must be 1 or 2.")
  if (!all(r$x %in% 0:1)) stop("`x` must be 0/1.")
  m <- match(r$item, bank$item)
  if (anyNA(m)) stop("Items missing from the bank: ", paste(utils::head(unique(r$item[is.na(m)])), collapse = ", "))
  if (anyNA(match(r$person, persons$person))) stop("Responses for persons not in `persons`.")
  if (anyDuplicated(r[c("person", "item")]))
    stop("Some items were given to the same person twice; the MVP assumes disjoint forms.")
  r$b <- bank$b[m]
  r$exposed <- as.logical(bank$exposed[m])
  if (!is.null(r$rt)) {
    if (is.null(bank$beta)) stop("Response times need `beta` (time intensity) in the bank.")
    r$beta <- bank$beta[m]
  }
  a2 <- r[r$attempt == 2, ]
  n_exp <- tapply(a2$exposed, a2$person, sum)
  n_new <- tapply(!a2$exposed, a2$person, sum)
  if (length(n_exp) != nrow(persons) || !all(r$person[r$attempt == 1] %in% names(n_exp)))
    stop("Every person needs both attempts.")
  if (any(n_exp < 5) || any(n_new < 5))
    stop("Attempt 2 needs at least 5 exposed and 5 new items per person.")
  structure(list(responses = r, persons = persons, bank = bank), class = "rt_data")
}

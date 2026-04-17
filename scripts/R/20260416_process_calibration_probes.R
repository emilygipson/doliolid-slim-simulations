.libPaths(c("/scratch/eeg37520/Rlibs", .libPaths()))
TARGET_PI <- 0.0066
TAIL_FRACTION <- 0.20
base_dir <- "/scratch/eeg37520/doliolid_slim"
param_file <- file.path(base_dir, "20260409_calibration_probes_all.txt")
cal_log_dir <- file.path(base_dir, "calibration_logs")
out_dir <- file.path(base_dir, "sweeps")
params <- read.table(param_file, header = FALSE,
                     col.names = c("probe_id", "K", "ooz", "mort", "mu"))
cat("Loaded", nrow(params), "probe definitions\n")
read_probe_log <- function(probe_id, K, ooz, mort, mu) {
  pattern <- paste0("calibration_11k_combo", probe_id, "_K", K, "_mu")
  candidates <- list.files(cal_log_dir, pattern = pattern, full.names = TRUE)
  if (length(candidates) == 0) { warning(paste("No log for probe", probe_id)); return(NULL) }
  f <- candidates[1]
  d <- tryCatch(
    read.csv(f, header = TRUE),
    error = function(e) { warning(paste("Failed:", f)); return(NULL) }
  )
  if (is.null(d) || nrow(d) < 5) return(NULL)
  if (!("pi" %in% names(d))) { warning(paste("No pi column in", f)); return(NULL) }
  d$pi <- as.numeric(d$pi)
  d <- d[!is.na(d$pi), ]
  if (nrow(d) < 5) return(NULL)
  tail_start <- floor(nrow(d) * (1 - TAIL_FRACTION)) + 1
  tail_data <- d[tail_start:nrow(d), ]
  tail_data <- tail_data[tail_data$pi > 0, ]
  if (nrow(tail_data) == 0) return(NULL)
  eq_pi_val <- mean(tail_data$pi, na.rm = TRUE)
  if (is.na(eq_pi_val) || eq_pi_val <= 0) return(NULL)
  data.frame(probe_id=probe_id, K=K, ooz=ooz, mort=mort, mu=mu,
             eq_pi=eq_pi_val, sd_pi=sd(tail_data$pi, na.rm=TRUE),
             n_tail=nrow(tail_data), final_tick=max(d$cycle), total_rows=nrow(d))
}
cat("Reading calibration logs...\n")
probe_results <- do.call(rbind, mapply(read_probe_log,
  params$probe_id, params$K, params$ooz, params$mort, params$mu, SIMPLIFY=FALSE))
cat("Successfully read", nrow(probe_results), "of", nrow(params), "probes\n")
missing <- setdiff(params$probe_id, probe_results$probe_id)
if (length(missing) > 0) cat("WARNING: Missing probes:", paste(missing, collapse=", "), "\n")
write.table(probe_results, file.path(out_dir, "calibration_probe_diagnostics.tsv"),
            sep="\t", row.names=FALSE, quote=FALSE)
probe_results$cell <- paste0("K", probe_results$K, "_ooz", probe_results$ooz, "_mort", probe_results$mort)
cells <- unique(probe_results$cell)
cat("\nInterpolating mu for", length(cells), "cells at target pi =", TARGET_PI, "\n\n")
calibrated <- data.frame()
for (cell_id in cells) {
  cd <- probe_results[probe_results$cell == cell_id, ]
  cd <- cd[order(cd$mu), ]
  cd <- cd[!is.na(cd$eq_pi) & cd$eq_pi > 0, ]
  K_val <- cd$K[1]; ooz_val <- cd$ooz[1]; mort_val <- cd$mort[1]; np <- nrow(cd)
  if (np < 2) {
    cat(sprintf("  %s: SKIPPED (%d valid probes)\n", cell_id, np))
    calibrated <- rbind(calibrated, data.frame(K=K_val, ooz=ooz_val, mort=mort_val,
      mu_calibrated=NA, method="insufficient", pi_min=NA, pi_max=NA, n_probes=np))
    next
  }
  pr <- range(cd$eq_pi)
  if (TARGET_PI < pr[1]) {
    fit <- lm(log(eq_pi) ~ log(mu), data=cd)
    mu_i <- exp((log(TARGET_PI) - coef(fit)[1]) / coef(fit)[2])
    meth <- "extrap_below"
    cat(sprintf("  %s: BELOW [%.5f,%.5f] extrap mu=%.3e\n", cell_id, pr[1], pr[2], mu_i))
  } else if (TARGET_PI > pr[2]) {
    fit <- lm(log(eq_pi) ~ log(mu), data=cd)
    mu_i <- exp((log(TARGET_PI) - coef(fit)[1]) / coef(fit)[2])
    meth <- "extrap_above"
    cat(sprintf("  %s: ABOVE [%.5f,%.5f] extrap mu=%.3e\n", cell_id, pr[1], pr[2], mu_i))
  } else {
    below <- cd[cd$eq_pi <= TARGET_PI, ]; above <- cd[cd$eq_pi >= TARGET_PI, ]
    if (nrow(below)==0 || nrow(above)==0) {
      fit <- lm(log(eq_pi) ~ log(mu), data=cd)
      mu_i <- exp((log(TARGET_PI) - coef(fit)[1]) / coef(fit)[2]); meth <- "loglinear"
    } else {
      lo <- below[which.max(below$eq_pi), ]; hi <- above[which.min(above$eq_pi), ]
      frac <- (log(TARGET_PI)-log(lo$eq_pi)) / (log(hi$eq_pi)-log(lo$eq_pi))
      mu_i <- exp(log(lo$mu) + frac*(log(hi$mu)-log(lo$mu))); meth <- "interpolate"
    }
    cat(sprintf("  %s: %s mu=%.4e [%.5f,%.5f]\n", cell_id, meth, mu_i, pr[1], pr[2]))
  }
  calibrated <- rbind(calibrated, data.frame(K=K_val, ooz=ooz_val, mort=mort_val,
    mu_calibrated=mu_i, method=meth, pi_min=pr[1], pi_max=pr[2], n_probes=np))
}
calibrated <- calibrated[order(calibrated$K, calibrated$ooz, calibrated$mort), ]
write.table(calibrated, file.path(out_dir, "calibrated_mu_all_cells.tsv"),
            sep="\t", row.names=FALSE, quote=FALSE)
cat("\n=== CALIBRATED MU SUMMARY ===\n")
for (k in sort(unique(calibrated$K))) {
  cat(sprintf("\nK = %d:\n", k))
  s <- calibrated[calibrated$K == k, ]
  for (i in seq_len(nrow(s)))
    cat(sprintf("  ooz=%.2f mort=%.2f  mu=%.4e  [%s]\n", s$ooz[i], s$mort[i], s$mu_calibrated[i], s$method[i]))
}
cat("\nDone.\n")

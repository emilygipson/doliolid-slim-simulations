# CALIBRATION CONVERGENCE CHECKER
#
# Reads all calibration log CSVs from the cluster (after scp), extracts the
# final pi from each, computes ratio to target, and produces a summary table.
# Works for both neutral and pursel calibration logs.
#
# Usage: update cal_dir to point at your local copy of calibration_logs/
#        then source the script in RStudio.
#
# Emily Gipson, UGA mfflab

# ---- Parameters ----

# Update these paths to your local copies
neutral_cal_dir <- "C:/Users/emily/Downloads/calibration_logs"
pursel_cal_dir <- "C:/Users/emily/Downloads/pursel_calibration"
target_pi <- 0.0066
tolerance <- 0.15  # within 15% = converged

# ---- Neutral calibration check ----

check_neutral_calibration <- function(cal_dir, target_pi, tolerance) {

  csv_files <- list.files(cal_dir, pattern = "^calibration_combo.*\\.csv$",
                           full.names = TRUE)

  if (length(csv_files) == 0) {
    cat("No neutral calibration files found in", cal_dir, "\n")
    return(invisible(NULL))
  }

  results <- data.frame(
    file = character(),
    combo = integer(),
    K = integer(),
    mu = character(),
    ooz = numeric(),
    mort = numeric(),
    final_pi = numeric(),
    ratio = numeric(),
    status = character(),
    stringsAsFactors = FALSE
  )

  for (f in csv_files) {
    fname <- basename(f)

    # Parse filename: calibration_combo4_K5000_mu1.2e-06_ooz50_mort5.csv
    parts <- regmatches(fname,
      regexec("calibration_combo(\\d+)_K(\\d+)_mu([^_]+)_ooz(\\d+)_mort(\\d+)\\.csv",
              fname))[[1]]

    if (length(parts) < 6) next

    combo_id <- as.integer(parts[2])
    K <- as.integer(parts[3])
    mu_str <- parts[4]
    ooz <- as.numeric(parts[5]) / 100
    mort <- as.numeric(parts[6]) / 100

    # Read last line for final pi
    lines <- readLines(f, warn = FALSE)
    last_line <- lines[length(lines)]
    fields <- strsplit(last_line, ",")[[1]]

    # Neutral logs: cycle, num_nurses, total_N, pi (4 columns)
    final_pi <- as.numeric(fields[4])

    ratio <- final_pi / target_pi

    if (ratio >= (1 - tolerance) & ratio <= (1 + tolerance)) {
      status <- "OK"
    } else if (ratio < (1 - tolerance)) {
      status <- "LOW"
    } else {
      status <- "HIGH"
    }

    results <- rbind(results, data.frame(
      file = fname,
      combo = combo_id,
      K = K,
      mu = mu_str,
      ooz = ooz,
      mort = mort,
      final_pi = final_pi,
      ratio = ratio,
      status = status,
      stringsAsFactors = FALSE
    ))
  }

  # Sort by combo, then by mu (to show round progression)
  results <- results[order(results$combo, results$mu), ]

  cat("\n===== NEUTRAL CALIBRATION SUMMARY =====\n")
  cat("Target pi:", target_pi, "\n")
  cat("Tolerance:", tolerance * 100, "%\n")
  cat("Acceptable range:", target_pi * (1 - tolerance), "-",
      target_pi * (1 + tolerance), "\n\n")

  # Print grouped by combo
  for (cid in sort(unique(results$combo))) {
    sub <- results[results$combo == cid, ]
    cat("Combo", cid, "(K=", sub$K[1], ", ooz=", sub$ooz[1],
        ", mort=", sub$mort[1], "):\n")
    for (i in 1:nrow(sub)) {
      cat("  mu=", sub$mu[i], "  pi=", sprintf("%.6f", sub$final_pi[i]),
          "  ratio=", sprintf("%.3f", sub$ratio[i]),
          "  [", sub$status[i], "]\n")
    }
  }

  # Summary counts
  latest <- results[!duplicated(results$combo, fromLast = TRUE), ]
  cat("\n--- Latest round per combo ---\n")
  cat("Converged (OK):", sum(latest$status == "OK"), "of",
      nrow(latest), "\n")
  cat("Too low:", sum(latest$status == "LOW"), "\n")
  cat("Too high:", sum(latest$status == "HIGH"), "\n\n")

  return(invisible(results))
}

# ---- Pursel calibration check ----

check_pursel_calibration <- function(cal_dir, target_pi, tolerance) {

  csv_files <- list.files(cal_dir, pattern = "^pursel_\\d+_calibration_log\\.csv$",
                           full.names = TRUE)

  if (length(csv_files) == 0) {
    cat("No pursel calibration files found in", cal_dir, "\n")
    return(invisible(NULL))
  }

  results <- data.frame(
    file = character(),
    pursel_id = integer(),
    final_tick = integer(),
    final_pi = numeric(),
    ratio = numeric(),
    seg_del = integer(),
    status = character(),
    stringsAsFactors = FALSE
  )

  for (f in csv_files) {
    fname <- basename(f)

    # Parse pursel ID from filename
    pid <- as.integer(regmatches(fname,
      regexec("pursel_(\\d+)_calibration_log\\.csv", fname))[[1]][2])

    # Read last line
    lines <- readLines(f, warn = FALSE)
    last_line <- lines[length(lines)]
    fields <- strsplit(last_line, ",")[[1]]

    # Pursel logs: cycle, num_nurses, total_N, pi, num_m2, pursel_id
    final_tick <- as.integer(fields[1])
    final_pi <- as.numeric(fields[4])
    seg_del <- as.integer(fields[5])

    ratio <- final_pi / target_pi

    if (ratio >= (1 - tolerance) & ratio <= (1 + tolerance)) {
      status <- "OK"
    } else if (ratio < (1 - tolerance)) {
      status <- "LOW"
    } else {
      status <- "HIGH"
    }

    results <- rbind(results, data.frame(
      file = fname,
      pursel_id = pid,
      final_tick = final_tick,
      final_pi = final_pi,
      ratio = ratio,
      seg_del = seg_del,
      status = status,
      stringsAsFactors = FALSE
    ))
  }

  results <- results[order(results$pursel_id), ]

  cat("\n===== PURSEL CALIBRATION SUMMARY =====\n")
  cat("Target pi:", target_pi, "\n")
  cat("Tolerance:", tolerance * 100, "%\n")
  cat("Acceptable range:", target_pi * (1 - tolerance), "-",
      target_pi * (1 + tolerance), "\n\n")

  for (i in 1:nrow(results)) {
    cat("Pursel", results$pursel_id[i],
        ": tick=", results$final_tick[i],
        "  pi=", sprintf("%.6f", results$final_pi[i]),
        "  ratio=", sprintf("%.3f", results$ratio[i]),
        "  seg_del=", results$seg_del[i],
        "  [", results$status[i], "]\n")
  }

  cat("\nConverged (OK):", sum(results$status == "OK"), "of",
      nrow(results), "\n")
  cat("Too low:", sum(results$status == "LOW"), "\n")
  cat("Too high:", sum(results$status == "HIGH"), "\n\n")

  return(invisible(results))
}

# ---- Run both checks ----
# Uncomment and run after scp-ing log files locally:
#
# neutral_results <- check_neutral_calibration(neutral_cal_dir, target_pi, tolerance)
# pursel_results <- check_pursel_calibration(pursel_cal_dir, target_pi, tolerance)

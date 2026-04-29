# 20260324_bloom_founder_preliminary_figures.R
# Preliminary figures from K_NURSES=500 bloom founder sweep
# Input: bloom_founder_pooled_prod_results.tsv (in working directory)
# Output: 4 PNG figures at 300 dpi

# LOAD DATA

d <- read.delim("bloom_founder_pooled_prod_results.tsv", header = TRUE)

# Empirical reference values
emp_pi_bloom <- 0.00625
emp_pi_nonbloom <- 0.00670
emp_tajD <- -2.538
emp_n_unique <- 120  # out of 120
bg_pi <- d$bg_pi[1]  # simulated background pi

# Separate by sample size
d12 <- d[d$n == 12, ]
d120 <- d[d$n == 120, ]

# Aggregate by k
agg_fun <- function(sub) {
    ks <- sort(unique(sub$k))
    out <- data.frame(
        k = ks,
        mean_nuniq = tapply(sub$n_unique, sub$k, mean)[as.character(ks)],
        sd_nuniq = tapply(sub$n_unique, sub$k, sd)[as.character(ks)],
        mean_pi = tapply(sub$pi, sub$k, mean)[as.character(ks)],
        sd_pi = tapply(sub$pi, sub$k, sd)[as.character(ks)],
        mean_tajD = tapply(sub$tajD, sub$k, mean)[as.character(ks)],
        sd_tajD = tapply(sub$tajD, sub$k, sd)[as.character(ks)],
        p_all_unique = tapply(sub$n_unique, sub$k,
                              function(x) mean(x == max(sub$n)))[as.character(ks)]
    )
    rownames(out) <- NULL
    return(out)
}

a12 <- agg_fun(d12)
a120 <- agg_fun(d120)

# FIGURE 1: Pi ratio (bloom / background) vs k

png("20260324_pi_ratio_vs_k.png", width = 7, height = 5, units = "in", res = 300)
par(mar = c(5, 5, 3, 1))

plot(a120$k, a120$mean_pi / bg_pi, type = "b", pch = 16, col = "steelblue",
     log = "x", ylim = c(0.85, 1.05),
     xlab = "Number of founding nurses (k)", ylab = expression(pi[bloom] / pi[background]),
     main = "Bloom diversity convergence on background",
     cex.lab = 1.2, cex.main = 1.2)

# Error bars for n=120
arrows(a120$k, (a120$mean_pi - a120$sd_pi) / bg_pi,
       a120$k, (a120$mean_pi + a120$sd_pi) / bg_pi,
       angle = 90, code = 3, length = 0.03, col = "steelblue")

# n=12
points(a12$k, a12$mean_pi / bg_pi, type = "b", pch = 17, col = "coral")
arrows(a12$k, (a12$mean_pi - a12$sd_pi) / bg_pi,
       a12$k, (a12$mean_pi + a12$sd_pi) / bg_pi,
       angle = 90, code = 3, length = 0.03, col = "coral")

# Reference lines
abline(h = 1.0, lty = 2, col = "gray40")
abline(h = emp_pi_bloom / emp_pi_nonbloom, lty = 3, col = "darkgreen", lwd = 2)

legend("bottomright",
       legend = c("n = 120", "n = 12",
                  "Perfect match (ratio = 1)",
                  paste0("Empirical ratio (", round(emp_pi_bloom / emp_pi_nonbloom, 3), ")")),
       pch = c(16, 17, NA, NA), lty = c(1, 1, 2, 3),
       col = c("steelblue", "coral", "gray40", "darkgreen"),
       lwd = c(1, 1, 1, 2), cex = 0.85)

dev.off()
cat("Saved: 20260324_pi_ratio_vs_k.png\n")

# FIGURE 2: Mean Tajima's D vs k

png("20260324_tajD_vs_k.png", width = 7, height = 5, units = "in", res = 300)
par(mar = c(5, 5, 3, 1))

yrange <- range(c(a120$mean_tajD - a120$sd_tajD,
                  a120$mean_tajD + a120$sd_tajD,
                  a12$mean_tajD - a12$sd_tajD,
                  a12$mean_tajD + a12$sd_tajD,
                  emp_tajD))

plot(a120$k, a120$mean_tajD, type = "b", pch = 16, col = "steelblue",
     log = "x", ylim = yrange,
     xlab = "Number of founding nurses (k)", ylab = "Tajima's D",
     main = "Tajima's D of bloom sample vs number of founders",
     cex.lab = 1.2, cex.main = 1.2)

arrows(a120$k, a120$mean_tajD - a120$sd_tajD,
       a120$k, a120$mean_tajD + a120$sd_tajD,
       angle = 90, code = 3, length = 0.03, col = "steelblue")

points(a12$k, a12$mean_tajD, type = "b", pch = 17, col = "coral")
arrows(a12$k, a12$mean_tajD - a12$sd_tajD,
       a12$k, a12$mean_tajD + a12$sd_tajD,
       angle = 90, code = 3, length = 0.03, col = "coral")

abline(h = 0, lty = 2, col = "gray40")
abline(h = emp_tajD, lty = 3, col = "darkgreen", lwd = 2)

legend("topright",
       legend = c("n = 120", "n = 12", "Neutral expectation (D = 0)",
                  paste0("Empirical bloom D (", emp_tajD, ")")),
       pch = c(16, 17, NA, NA), lty = c(1, 1, 2, 3),
       col = c("steelblue", "coral", "gray40", "darkgreen"),
       lwd = c(1, 1, 1, 2), cex = 0.85)

dev.off()
cat("Saved: 20260324_tajD_vs_k.png\n")

# FIGURE 3: Mean number of unique haplotypes vs k

png("20260324_n_unique_vs_k.png", width = 7, height = 5, units = "in", res = 300)
par(mar = c(5, 5, 3, 1))

plot(a120$k, a120$mean_nuniq, type = "b", pch = 16, col = "steelblue",
     log = "x", ylim = c(0, 125),
     xlab = "Number of founding nurses (k)", ylab = "Mean unique haplotypes in sample",
     main = "Haplotype uniqueness vs number of founders",
     cex.lab = 1.2, cex.main = 1.2)

points(a12$k, a12$mean_nuniq, type = "b", pch = 17, col = "coral")

# Reference lines at sample sizes
abline(h = 120, lty = 2, col = "steelblue", lwd = 0.8)
abline(h = 12, lty = 2, col = "coral", lwd = 0.8)

# Mark where n_unique plateaus due to bank diversity ceiling
# Add annotation
text(5000, 112, "Bank diversity ceiling\n(9,500 haplotypes, many shared)",
     cex = 0.75, col = "gray40", pos = 1)

legend("right",
       legend = c("n = 120", "n = 12", "All unique (n = 120)", "All unique (n = 12)"),
       pch = c(16, 17, NA, NA), lty = c(1, 1, 2, 2),
       col = c("steelblue", "coral", "steelblue", "coral"),
       cex = 0.85)

dev.off()
cat("Saved: 20260324_n_unique_vs_k.png\n")

# FIGURE 4: P(all unique) vs k with birthday problem overlay

# Analytical birthday problem: P(all unique) for n draws from pool of k
# P = prod_{i=0}^{n-1} (k-i)/k = prod_{i=0}^{n-1} (1 - i/k)
birthday_p_all_unique <- function(k, n) {
    if (k < n) return(0)
    p <- 1
    for (i in 0:(n - 1)) {
        p <- p * (1 - i / k)
    }
    return(p)
}

k_seq <- 10^seq(1, 6, length.out = 200)

bp12 <- sapply(k_seq, birthday_p_all_unique, n = 12)
bp120 <- sapply(k_seq, birthday_p_all_unique, n = 120)

png("20260324_p_all_unique_vs_k.png", width = 7, height = 5, units = "in", res = 300)
par(mar = c(5, 5, 3, 1))

plot(k_seq, bp120, type = "l", col = "steelblue", lwd = 2, log = "x",
     ylim = c(0, 1.05),
     xlab = "Number of founding nurses (k)",
     ylab = "P(all haplotypes unique in sample)",
     main = "Probability of all-unique sample vs number of founders",
     cex.lab = 1.2, cex.main = 1.2)

lines(k_seq, bp12, col = "coral", lwd = 2)

# Overlay simulation results
points(a120$k, a120$p_all_unique, pch = 16, col = "steelblue", cex = 1.2)
points(a12$k, a12$p_all_unique, pch = 17, col = "coral", cex = 1.2)

# 95% threshold
abline(h = 0.95, lty = 3, col = "gray40")
text(1e5, 0.97, "95% threshold", cex = 0.8, col = "gray40")

# Mark where simulation diverges from theory (bank ceiling)
arrows(2000, 0.15, 2000, 0.05, length = 0.08, col = "gray40")
text(2000, 0.20, "Simulation hits\nbank diversity ceiling", cex = 0.7, col = "gray40")

legend("bottomright",
       legend = c("Birthday problem (n = 120)", "Birthday problem (n = 12)",
                  "Simulation (n = 120)", "Simulation (n = 12)"),
       lty = c(1, 1, NA, NA), pch = c(NA, NA, 16, 17),
       col = c("steelblue", "coral", "steelblue", "coral"),
       lwd = c(2, 2, NA, NA), cex = 0.85)

dev.off()
cat("Saved: 20260324_p_all_unique_vs_k.png\n")

cat("\nAll figures saved. Check working directory.\n")

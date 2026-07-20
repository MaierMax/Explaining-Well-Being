#!/usr/bin/env Rscript
# =====================================================================
# 06_analysis_prep.R  —  Teil 1 (Aufgabe C1)
# Aufbau der 20 vollstaendigen MI-Analysedatensaetze.
#
# KEINE Transformationen, KEINE Standardisierung, KEINE Modelle.
# Ergebnis: code/Created Files for Analysis/analysis_base.rds
#           (benannte Liste imp01..imp20 mit je einem data.frame)
#
# Deterministisch (kein RNG). Bricht bei Assert-Verletzung ab.
# =====================================================================

suppressMessages(library(mice))

## ---- 0) Repo-Root robust bestimmen --------------------------------
root <- getwd()
if (basename(root) == "code") root <- dirname(root)
stopifnot(dir.exists(file.path(root, "Created DBs", "Cleaned DBs")),
          dir.exists(file.path(root, "code", "Created Files for Analysis")))

p_step1 <- file.path(root, "code", "Created Files for Analysis", "step1_lifesat_pmm.rds")
p_step2 <- file.path(root, "code", "Created Files for Analysis", "step2_features_amelia.rds")
p_targ  <- file.path(root, "Created DBs", "Cleaned DBs", "db1_targets_cleaned.csv")
p_clean <- file.path(root, "Created DBs", "Cleaned DBs", "cleaned_database.csv")
p_out   <- file.path(root, "code", "Created Files for Analysis", "analysis_base.rds")

cat("== 06_analysis_prep.R : Aufbau der 20 MI-Analysedatensaetze ==\n")
cat("Repo-Root:", root, "\n\n")

## ---- 1) Inputs laden ----------------------------------------------
step1 <- readRDS(p_step1)                         # mice::mids, m=20 (Happiness_Score)
step2 <- readRDS(p_step2)                         # Amelia,     m=20 (35 Features)
targ  <- read.csv(p_targ,  check.names = FALSE, stringsAsFactors = FALSE)
cd    <- read.csv(p_clean, check.names = FALSE, stringsAsFactors = FALSE)

M <- 20L
stopifnot(step1$m == M, step2$m == M)

## Referenz-Spaltenstruktur (44 Spalten) aus cleaned_database
cols_all  <- names(cd)                            # Zielreihenfolge des Outputs
meta_cols <- c("META_WEO_Gruppe", "META_Lambda_BIP",
               "META_LB_vs_Global", "META_LB_vs_Gruppe")   # F1..F4
key_cols  <- c("ISO3", "Country_Name", "Year")
tgt_cols  <- c("HDI", "Happiness_Score")
feat_orig <- setdiff(cols_all, c(key_cols, tgt_cols, meta_cols))   # 35 Features
stopifnot(length(feat_orig) == 35L)

## ---- 2) Namens-Rueckmapping (Amelia sanitisiert -> Original) -------
feat_san <- gsub("[^A-Za-z0-9]", "_", feat_orig)
am_names <- names(step2$imputations[[1]])
stopifnot(all(feat_san %in% am_names),            # alle 35 gefunden
          !any(duplicated(feat_san)))             # eindeutig / bijektiv
cat("Namens-Rueckmapping: alle 35 Features eindeutig zugeordnet.\n")

## ---- 3) META-Referenztabelle (ISO3 + Year -> F1..F4) --------------
## F3/F4 sind Character mit "" fuer die 6 Laender -> "" als NA behandeln.
meta_ref <- cd[, c("ISO3", "Year", meta_cols)]
for (m in c("META_LB_vs_Global", "META_LB_vs_Gruppe")) {
  meta_ref[[m]][meta_ref[[m]] == ""] <- NA
}
key_meta <- paste(meta_ref$ISO3, meta_ref$Year)

## Ziel-/HDI-Lookups
key_targ <- paste(targ$ISO3, targ$Year)

## Laender ohne Lambda (erwartete Restluecken bei F2/F3/F4)
lambda_missing_iso <- c("AFG", "ARE", "NIC", "PSE", "ROU", "SLV")

## ---- 4) Aufbau je Version j = 1..20 -------------------------------
build_one <- function(j) {
  am <- step2$imputations[[j]]                    # ISO3, Country_Name, Year + 35 (sanitisiert)

  df <- am[, key_cols]
  feat <- am[, feat_san, drop = FALSE]            # 35 Features
  names(feat) <- feat_orig                        # Originalnamen
  df <- cbind(df, feat)

  key_df <- paste(df$ISO3, df$Year)

  ## Happiness_Score aus der j-ten mice-Vervollstaendigung (volle Praezision)
  cj <- complete(step1, j)
  df$Happiness_Score <- cj$Happiness_Score[match(key_df, paste(cj$ISO3, cj$Year))]

  ## HDI (nie imputiert) aus db1_targets_cleaned
  df$HDI <- targ$HDI[match(key_df, key_targ)]

  ## F1..F4 per ISO3+Year (in allen 20 Versionen identisch)
  mi <- match(key_df, key_meta)
  for (m in meta_cols) df[[m]] <- meta_ref[[m]][mi]

  ## Spaltenreihenfolge exakt wie cleaned_database (44 Spalten), Zeilen ISO3+Year
  df <- df[, cols_all]
  df <- df[order(df$ISO3, df$Year), ]
  rownames(df) <- NULL
  df
}

cat("\nBaue 20 Versionen ...\n")
imp_list <- lapply(seq_len(M), build_one)
names(imp_list) <- sprintf("imp%02d", seq_len(M))

## Referenz (cleaned) in gleiche Zeilenreihenfolge bringen
cd_sorted <- cd[order(cd$ISO3, cd$Year), ]
rownames(cd_sorted) <- NULL
ref_key   <- paste(cd_sorted$ISO3, cd_sorted$Year)

## ---- 5) Pflicht-Asserts -------------------------------------------
n_fail <- 0L
check <- function(name, ok, detail = "") {
  status <- if (isTRUE(ok)) "PASS" else "FAIL"
  if (!isTRUE(ok)) n_fail <<- n_fail + 1L
  cat(sprintf("  [%s] %s%s\n", status, name,
              if (nzchar(detail)) paste0("  ->  ", detail) else ""))
}

cat("\n== Pflicht-Asserts ==\n")

## A1: 1904 Zeilen (119 x 16), identische Zeilenreihenfolge ueber alle 20
dims_ok <- all(vapply(imp_list, nrow, 0L) == 1904L)
n_ctry  <- length(unique(imp_list[[1]]$ISO3)); n_year <- length(unique(imp_list[[1]]$Year))
order_ok <- all(vapply(imp_list, function(d) identical(paste(d$ISO3, d$Year), ref_key), NA))
check("A1 Zeilen=1904 & Reihenfolge identisch", dims_ok && order_ok && n_ctry == 119L && n_year == 16L,
      sprintf("%d Laender x %d Jahre; alle 20 gleich sortiert=%s", n_ctry, n_year, order_ok))

## A2: 0 NA ausser F2/F3/F4 (je 96 NA, genau bei den 6 Laendern); F1 vollstaendig
nonmeta <- setdiff(cols_all, meta_cols)
na_nonmeta <- vapply(imp_list, function(d) sum(is.na(d[, nonmeta])), 0L)
na_f1 <- vapply(imp_list, function(d) sum(is.na(d$META_WEO_Gruppe)), 0L)
lam_cols <- c("META_Lambda_BIP", "META_LB_vs_Global", "META_LB_vs_Gruppe")
na_lam_ok <- all(vapply(imp_list, function(d) {
  all(vapply(lam_cols, function(m) {
    idx <- is.na(d[[m]])
    sum(idx) == 96L && setequal(unique(d$ISO3[idx]), lambda_missing_iso)
  }, NA))
}, NA))
check("A2 NA-Bilanz (nur F2/F3/F4 je 96 NA an 6 Laendern)",
      all(na_nonmeta == 0L) && all(na_f1 == 0L) && na_lam_ok,
      sprintf("Non-META NA=%d, F1 NA=%d, F2/F3/F4-Muster ok=%s",
              max(na_nonmeta), max(na_f1), na_lam_ok))

## A3: Spaltenset identisch mit cleaned_database (44 Spalten)
set_ok <- all(vapply(imp_list, function(d) setequal(names(d), cols_all) && ncol(d) == length(cols_all), NA))
check("A3 Spaltenset == cleaned_database (44 Spalten)", set_ok,
      sprintf("%d Spalten je Version", ncol(imp_list[[1]])))

## A4: Mittelwert jedes Features ueber 20 Versionen ~ cleaned_database (rel. Tol 1e-6)
feat_maxrel <- 0; feat_worst <- ""
for (f in feat_orig) {
  Mv <- vapply(imp_list, function(d) d[[f]], numeric(1904))
  mu <- rowMeans(Mv)
  ref <- cd_sorted[[f]]
  rel <- max(abs(mu - ref) / pmax(abs(ref), 1e-8))
  if (rel > feat_maxrel) { feat_maxrel <- rel; feat_worst <- f }
}
check("A4 Feature-Pool-Mittel ~ cleaned (rel<1e-6)", feat_maxrel < 1e-6,
      sprintf("max rel. Abw. = %.2e (%s)", feat_maxrel, feat_worst))

## A5: Beobachtete (nicht imputierte) Zellen ueber alle 20 Versionen identisch
##     Features: Beobachtung via Amelia-missMatrix; Happiness via mice-where.
mm <- step2$missMatrix
colnames(mm) <- ifelse(colnames(mm) %in% feat_san,
                       feat_orig[match(colnames(mm), feat_san)], colnames(mm))
## Reihenfolge der missMatrix = Original-Amelia-Reihenfolge (ISO3,Year wie step2$imputations[[1]])
amel_key <- paste(step2$imputations[[1]]$ISO3, step2$imputations[[1]]$Year)
obs_identical <- TRUE; obs_detail <- ""
for (f in feat_orig) {
  obs_rows_amord <- !mm[, f]
  Mv <- vapply(imp_list, function(d) d[[f]], numeric(1904))       # sortiert nach ref_key
  ## missMatrix-Zeilen auf ref_key-Reihenfolge umsortieren
  obs_rows <- obs_rows_amord[match(ref_key, amel_key)]
  if (any(obs_rows)) {
    rng <- apply(Mv[obs_rows, , drop = FALSE], 1, function(x) max(x) - min(x))
    if (max(rng) > 0) { obs_identical <- FALSE; obs_detail <- paste0("Feature ", f) }
  }
}
## Happiness: beobachtete Zellen identisch ueber die 20 Versionen
Hs <- vapply(imp_list, function(d) d$Happiness_Score, numeric(1904))
hap_obs_amord <- !step1$where[, "Happiness_Score"]
hap_obs <- hap_obs_amord[match(ref_key, paste(step1$data$ISO3, step1$data$Year))]
hap_rng <- apply(Hs[hap_obs, , drop = FALSE], 1, function(x) max(x) - min(x))
if (max(hap_rng) > 0) { obs_identical <- FALSE; obs_detail <- paste(obs_detail, "Happiness_Score") }
check("A5 beobachtete Zellen identisch ueber 20 Versionen", obs_identical,
      if (nzchar(obs_detail)) obs_detail else "Features + Happiness_Score ok")

## A6: F2, F3 je Land konstant; F1, F4 je Land x Jahr ueber alle 20 Versionen identisch
##     (Jahresvariation von F1/F4 ist erlaubt.)
const_ok <- TRUE
for (m in c("META_Lambda_BIP", "META_LB_vs_Global")) {
  v <- tapply(imp_list[[1]][[m]], imp_list[[1]]$ISO3,
              function(z) length(unique(z[!is.na(z)])) > 1)
  if (any(v, na.rm = TRUE)) const_ok <- FALSE
}
## F1..F4 ueber die 20 Versionen identisch (gleiche Metadaten-Quelle)
meta_same <- all(vapply(meta_cols, function(m) {
  base <- imp_list[[1]][[m]]
  all(vapply(imp_list, function(d) identical(d[[m]], base), NA))
}, NA))
check("A6 F2/F3 landkonstant & F1..F4 in allen 20 identisch", const_ok && meta_same,
      sprintf("F2/F3 konstant=%s, META ueber Versionen identisch=%s", const_ok, meta_same))

## A7: HDI in allen 20 Versionen identisch und == db1_targets
hdi_base <- imp_list[[1]]$HDI
hdi_same <- all(vapply(imp_list, function(d) identical(d$HDI, hdi_base), NA))
hdi_ref  <- targ$HDI[match(ref_key, key_targ)]
hdi_eq   <- max(abs(hdi_base - hdi_ref)) == 0
check("A7 HDI identisch ueber 20 & == db1_targets", hdi_same && hdi_eq,
      sprintf("ueber Versionen identisch=%s, max|Diff zu targets|=%g", hdi_same, max(abs(hdi_base - hdi_ref))))

## ---- Informativ: Happiness-Pool-Abweichung (Rundung in cleaned) ----
hap_mu  <- rowMeans(Hs)
hap_rel <- max(abs(hap_mu - cd_sorted$Happiness_Score) / pmax(abs(cd_sorted$Happiness_Score), 1e-8))
cat(sprintf("\n  [INFO] Happiness_Score Pool-Mittel vs. cleaned: max rel. Abw. = %.2e\n", hap_rel))
cat("         (erwartet ~2e-4; cleaned_database rundet Happiness, Rohwerte bleiben ungerundet)\n")
if (hap_rel > 1e-2) { n_fail <- n_fail + 1L; cat("  [FAIL] Happiness-Pool-Sanity (>1e-2)\n") }

## ---- 6) Konsolen-Protokoll: Dimensionen & NA-Bilanz ---------------
cat("\n== Dimensionen & NA-Bilanz je Version ==\n")
cat(sprintf("  %-6s %6s %5s %8s %8s\n", "Vers.", "Zeilen", "Spal.", "NA-ges", "NA-META"))
for (nm in names(imp_list)) {
  d <- imp_list[[nm]]
  cat(sprintf("  %-6s %6d %5d %8d %8d\n", nm, nrow(d), ncol(d),
              sum(is.na(d)), sum(is.na(d[, meta_cols]))))
}

## ---- 7) Output speichern ------------------------------------------
if (n_fail == 0L) {
  saveRDS(imp_list, p_out)
  cat(sprintf("\nAlle Asserts PASS. Output geschrieben:\n  %s\n", p_out))
} else {
  stop(sprintf("%d Assert(s) fehlgeschlagen - Output NICHT geschrieben.", n_fail))
}

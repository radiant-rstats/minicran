selMakeRepo <- function(
  pkgs, path, minicran, repos = getOption("repos"),
  type = "source", Rversion = R.version, ...
) {

  # minicran_avail <- miniCRAN::pkgAvail(repos = minicran, type = type, Rversion = Rversion)[, "Version"]
  minicran_avail <- miniCRAN::pkgAvail(path, type = type, Rversion = Rversion)[, "Version"]
  cran_avail <- miniCRAN::pkgAvail(repos = repos, type = type, Rversion = Rversion)[, "Version"]

  ## in dependent pkgs but not in miniCRAN repo
  to_fetch <- pkgs[!pkgs %in% names(minicran_avail)]

  ## not in dependent pkgs but in miniCRAN repo
  to_remove <- minicran_avail[!names(minicran_avail) %in% pkgs]

  ## which packages should be updated
  to_compare <- intersect(names(cran_avail), names(minicran_avail))

  pkgs_comp <- data.frame(
    compare = to_compare,
    pkgs = cran_avail[to_compare],
    minicran = minicran_avail[to_compare],
    stringsAsFactors = FALSE
  )

  to_update <- apply(pkgs_comp, 1, function(x) compareVersion(x[2], x[3]))
  to_update <- names(to_update[to_update == 1])

  to_fetch <- c(to_update, to_fetch)

  ## selective set of packages to download and add to repo
  dwnload <- makeRepo(to_fetch, path = path, type = type, Rversion = Rversion, ...)

  ## returning packages to remove
  if (length(to_remove) > 0) {
    cat("Consider removing", type, ifelse(is.list(Rversion), Rversion$version.string, Rversion), "remove:\n")
    print(to_remove)
  }
  invisible(to_remove)
}

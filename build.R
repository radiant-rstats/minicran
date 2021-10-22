## install script for R(adiant) @ Rady School of Management (MBA and MSBA)
owd <- getwd()
options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))
repos = c(
  RSM = "https://rsm-compute-01.ucsd.edu:4242/rsm-msba/__linux__/focal/latest",
  RSPM = "https://packagemanager.rstudio.com/all/__linux__/focal/latest",
  MINICRAN = "https://radiant-rstats.github.io/minicran/",
  CRAN = "https://cloud.r-project.org"
)

os <- Sys.info()["sysname"]
repos <- if (os == "Linux") repos else repos[c(3, 4, 1, 2)]
options(repos = repos)

build <- function(type = "binary", os="") {

  update.packages(lib.loc = .libPaths()[1], ask = FALSE)

  install <- function(x) if (!x %in% installed.packages()) install.packages(x, lib = .libPaths()[1])
  resp <- sapply(
    c("radiant", "gitgadget", "miniUI", "webshot", "tinytex", "usethis", "svglite", "remotes"),
    install
  )
  remotes::install_github("radiant-rstats/radiant.update", upgrade = "never")

  ## needed for windoze
  pkgs <- new.packages(lib.loc = .libPaths()[1], ask = FALSE)
  if (length(pkgs) > 0) {
    install.packages(pkgs)
  }

  # see https://github.com/wch/webshot/issues/25#event-740360519
  if (is.null(webshot:::find_phantom())) webshot::install_phantomjs()
}

rv <- R.Version()
rv <- paste(rv$major, rv$minor, sep = ".")

if (rv < "3.6") {
  cat("Radiant requires R-3.6.0 or later. Please install the latest\nversion of R from https://cloud.r-project.org/")
} else {

  os <- Sys.info()["sysname"]
  if (os == "Windows") {
    lp <- .libPaths()[grepl("Documents",.libPaths())]
    if (grepl("(Prog)|(PROG)", Sys.getenv("R_HOME"))) {
      rv <- paste(rv$major, rv$minor, sep = ".")
      cat(paste0("It seems you installed R in the Program Files directory.\nPlease uninstall R and re-install into C:\\R\\R-",rv),"\n\n")
    } else if (length(lp) > 0) {

      cat("Installing R-packages in the directory printed below often causes\nproblems on Windows. Please remove the 'Documents/R' directory,\nclose and restart R, and run the script again.\n\n")
      cat(paste0(lp, collapse = "\n"),"\n\n")
    } else {
      build()
    }
  } else if (os == "Darwin") {

    resp <- system("sw_vers -productVersion", intern = TRUE)
    if (resp < "10.9") {
      cat("The version of OSX on your mac is no longer supported by R. You will need to upgrade the OS before proceeding\n\n")
    } else {
      build()
    }
  } else {
    build(os = "Linux")
  }
}

setwd(owd)

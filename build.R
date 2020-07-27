## install script for R(adiant) @ Rady School of Management (MBA and MSBA)
cdir <- getwd()
options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))
repos <- c(
  "https://radiant-rstats.github.io/minicran/",
  "https://rsm-compute-01.ucsd.edu:4242/rsm-msba/__linux__/focal/latest",
  "https://cloud.r-project.org"
)

build <- function(type = "binary", os="") {

  repos_fun <- ifelse(os == "Linux", repos[2], repos[1])
  update.packages(lib.loc = .libPaths()[1], ask = FALSE, repos = repos_fun, type = type)

  install <- function(x) if (!x %in% installed.packages()) install.packages(x, lib = .libPaths()[1], repos = repos_fun, type = type)
  resp <- sapply(
    c("radiant", "gitgadget", "miniUI", "webshot", "tinytex", "usethis", "radiant.update", "svglite"),
    install
  )

  ## needed for windoze
  pkgs <- new.packages(lib.loc = .libPaths()[1], repos = repos_fun, type = type, ask = FALSE)
  if (length(pkgs) > 0) {
    install.packages(pkgs, repos = repos_fun, type = type)
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
    if (as.integer(strsplit(resp, "\\.")[[1]][2]) < 9) {
      cat("The version of OSX on your mac is no longer supported by R. You will need to upgrade the OS before proceeding\n\n")
    } else {
      build()
    }
  } else {
    build(type = "source", os = "Linux")
  }
}

setwd(cdir)

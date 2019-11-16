repos <- c(
  "https://radiant-rstats.github.io/minicran/",
  "https://rsm-compute-01.ucsd.edu:4242/rsm-msba/__linux__/bionic/latest",
  "https://cran.rstudio.com"
)

## install script for R(adiant) @ Rady School of Management (MBA and MSBA)
build <- function(type = "binary", os = "") {
  repos_fun <- ifelse(os == "Linux", repos[2], repos[1])
  ## get list of packages to update
  op <- old.packages(
    lib.loc = .libPaths()[1],
    repos = repos_fun,
    type = type
  )

  ## keep track of any package install issues (windoze)
  err_packages <- c()

  ## keep track of loaded name space on Windoze
  lns <- loadedNamespaces()

  if (length(op) > 0) {
    op <- op[,"Package"]

    os <- Sys.info()["sysname"]
    if (os == "Windows") {
      if ("yaml" %in% op && "yaml" %in% lns) {
        op <- op[-which(op == "yaml")]
        err_packages <- "yaml"
      }
    }
  }

  ## installs and unpacks one at time
  ## seems more robust than update.packages
  if (length(op) > 0) {
    cat("\n#################################################\n")
    cat("Updating previously installed packages")
    cat("\n#################################################\n\n")

    for (p in op) {
      if (p %in% lns) {
        err <- try(unloadNamespace(p), silent = TRUE)
        if (inherits(err, "try-error")) {
          cat("** There might be an issue updating package", p, "**\n")
          cat(err, "\n")
          err_packages <- c(err_packages, p)
        }
        if (p == "yaml") loadNamespace("yaml")
      }

      ## sometimes trying to install dependencies (e.g., Matrix) causes problems
      ## all deps should already be available in op by using the minicran package
      ## and all packages will be installed 1-by-1
      update.packages(
        lib.loc = .libPaths()[1], ask = FALSE, repos = repos_run,
        type = type, oldPkgs = p, dependencies = FALSE
      )
    }
  }

  ## additional packages ... not required but useful
  np <- new.packages(lib.loc = .libPaths()[1], repos = repos_fun, type = type, ask = FALSE)

  if (length(np) > 0) {
    cat("\n#################################################\n")
    cat("Installing new packages")
    cat("\n#################################################\n\n")

    for (p in np) {
      if (p %in% lns) {
        err <- try(unloadNamespace(p), silent = TRUE)
        if (inherits(err, "try-error")) {
          cat("** There might be an issue installing package", p, "**\n")
          cat(err, "\n")
          err_packages <- c(err_packages, p)
        }
        if (p == "yaml") loadNamespace("yaml")
      }
      ## sometimes trying to install dependencies (e.g., Matrix) causes problems
      ## all deps should already be available in op by using the minicran package
      ## and all packages will be installed 1-by-1
      install.packages(p, repos = repos_fun, type = type, dependencies = FALSE)
    }
  }

  # see https://github.com/wch/webshot/issues/25#event-740360519
  if (is.null(webshot:::find_phantom())) {
    webshot::install_phantomjs()
  }

  if (length(err_packages) == 0 | identical(err_packages, "yaml")) {
    message('\nTesting if Radiant can be loaded ...')
    success <- "\nRadiant update successfully completed\n"
    failure <- "\nRadiant update attempt was unsuccessful. Please copy the source command below, restart R(studio), and then paste the command into the R(studio) console and press return. If the update is still not successful, please send an email to radiant@rady.ucsd.edu with screen shots of the output shown in R(studio).\n\nsource('https://raw.githubusercontent.com/radiant-rstats/minicran/gh-pages/update.R')\n\n-------------------------------------------------------------------------------------\n"
    os <- Sys.info()["sysname"]
    if (os == "Windows") {
      if (rstudioapi::versionInfo()$version >= "1.1.383") {
        ret <- suppressPackageStartupMessages(require("radiant"))
        if (ret) {
          message(success)
        } else {
          message(failure)
        }
      } else {
        ## require(...) reliably causes Rstudio crash (1.1.359)
        cmd <- "source('https://raw.githubusercontent.com/radiant-rstats/minicran/gh-pages/win_check.R')"
        ret <- .rs.restartR(cmd)
      }
    } else {
      ret <- suppressPackageStartupMessages(require("radiant"))
      if (ret) {
        message(success)
      } else {
        message(failure)
      }
    }
  }

  return(unique(err_packages))
}

updater <- function() {

  ul <- try(
    sapply(
      c("radiant", "radiant.multivariate", "radiant.model", "radiant.basics", "radiant.design", "radiant.data"),
      unloadNamespace),
    silent = TRUE
  )

  rv <- R.Version()

  if (as.numeric(rv$major) < 3 || as.numeric(rv$minor) < 5) {
    message("Radiant requires R-3.5.0 or later. Please install the latest\nversion of R from https://cloud.r-project.org/")
  } else {

    os <- Sys.info()["sysname"]
    if (os == "Windows") {
      build()
    } else if (os == "Darwin") {
      resp <- system("sw_vers -productVersion", intern = TRUE)
      if (as.integer(strsplit(resp, "\\.")[[1]][2]) < 9) {
        message("Your version of macOS is no longer supported by R. You will need to upgrade the OS before proceeding\n\n")
      } else {
        build()
      }
    } else {
      build(type = "source", os = "Linux")
    }
  }
}

err <- updater()

# err <- c("yaml", "Matrix", "radiant", "radiant.model")
# err <- c("yaml", "Matrix")
# err <- c()
err <- err[!err %in% installed.packages()]

## https://stackoverflow.com/questions/50422627/different-results-from-deparse-in-r-3-4-4-and-r-3-5
dctrl <- if (getRversion() > "3.4.4") c("keepNA", "niceNames") else "keepNA"

if (length(err) > 0) {
  cat("\n\n###############################################################\n\n")
  cat("  Some packages were not successfully installed or updated\n\n")
  cat("  Restart R(studio) and use the command(s) below to install these packages:\n\n")
  rerr <- grepl("^radiant", err)
  if (sum(rerr) > 0) {
    err_radiant <- paste0(deparse(err[rerr], control = dctrl, width.cutoff = 500L), collapse = "")
    err <- paste0(deparse(err[!rerr], control = dctrl, width.cutoff = 500L), collapse = "")
    if (length(err) > 0) {
      cat(paste0("  install.packages(", err, ", repos = \"https://cran.rstudio.com\", type = \"binary\")\n"))
    }
    cat(paste0("  install.packages(", err_radiant, ", repos = \"https://radiant-rstats.github.io/minicran/\", type = \"binary\")\n"))
  } else {
    err <- paste0(deparse(err, control = dctrl, width.cutoff = 500L), collapse = "")
    cat(paste0("  install.packages(", err, ", repos = \"https://cran.rstudio.com\", type = \"binary\")\n"))
  }
  cat("\n###############################################################\n\n")
}

rm(updater, build, err)

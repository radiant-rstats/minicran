## install script for R(adiant) @ Rady School of Management (MBA)
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

build <- function(type = ifelse(os == "Linux", "source", "binary")) {
  update.packages(lib.loc = .libPaths()[1], ask = FALSE, type = type)

  install <- function(x) {
    pkgs <- x[!x %in% installed.packages()]
    if (length(pkgs) > 0) install.packages(pkgs, lib = .libPaths()[1], type = type)
  }
  install(
    c(
      "radiant", "remotes", "devtools", "roxygen2", "testthat",
      "gitgadget", "tinytex", "haven", "readxl", "writexl", "miniUI",
      "caret", "ranger", "gbm", "dbplyr", "DBI", "RSQLite", "usethis",
      "xgboost"
    )
  )

  remotes::install_github("radiant-rstats/radiant.update", upgrade = "never")

  pkgs <- new.packages(
    lib.loc = .libPaths()[1],
    repos = repos[1],
    ask = FALSE
  )

  if (length(pkgs) > 0) {
    install.packages(pkgs, type = type)
  }
}

readliner <- function(text, inp = "", resp = "[yYnN]") {
  while (!grepl(resp, inp)) inp <- readline(text)
  inp
}

rv <- R.Version()
rv <- paste(rv$major, rv$minor, sep = ".")

if (rv < "3.6") {
  cat("Radiant requires R-3.6.0 or later. Please install the latest\nversion of R from https://cloud.r-project.org/")
} else {

  os <- Sys.info()["sysname"]
  if (os == "Windows") {

    build()

    if (!require("installr")) {
      install.packages("installr")
      library("installr")
    }

    installr::install.Rtools()
    installr::install.git()

    ## get putty for ssh
    page <- readLines("http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html", warn = FALSE)
    pat <- "//the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-[0-9.]+-installer.msi"
    URL <- paste0("http:",regmatches(page,regexpr(pat,page))[1])

    installr::install.URL(URL)

    cat("\n\nInstallation on Windows complete. Close R and (re)start Rstudio\n\n")
  } else if (os == "Darwin") {

    ## from http://unix.stackexchange.com/a/712
    resp <- system("sw_vers -productVersion", intern = TRUE)

    if (resp < "10.9") {
      cat("The version of OSX on your mac is no longer supported by R. You will need to upgrade the OS before proceeding\n\n")
    } else {

      build()

      ## may still need xcode for some things
      xc <- system("xcode-select --install", ignore.stderr = TRUE)
      if (xc == 1) {
        cat("\n\nXcode command line tools are already installed\n\n")
      } else {
        cat("\n\nXcode command line tools were successfully installed\n\n")
      }

      gfortran <- suppressWarnings(system("which gfortran", intern = TRUE))
      if (length(gfortran) == 0) {
        # URL <- "https://cloud.r-project.org/bin/macosx/tools/gfortran-4.2.3.pkg"
        URL <- "https://cran.r-project.org/bin/macosx/tools/gfortran-6.1.pkg"
        setwd(tempdir())
        download.file(URL, "gfortran.pkg")
        system("open gfortran.pkg")
        cat("Please use gfortran.pkg to install gfortran on your Mac\n")
      } else {
        cat("Gfortran is already installed\n")
      }

      clang <- suppressWarnings(system("which clang", intern = TRUE))
      if (length(clang) == 0) {
        # URL <- "https://www.dropbox.com/s/3i77fzmxzx7koat/clang4-r.pkg?dl=1"
        URL <- "https://cran.r-project.org/bin/macosx/tools/clang-6.0.0.pkg"
        setwd(tempdir())
        download.file(URL, "clang4.pkg")
        system("open clang4.pkg")
        cat("Please use clang4.pkg to install clang on your Mac\n")
      } else {
        cat("Clang is already installed\n")
      }

      hb <- suppressWarnings(system("which brew", intern = TRUE))
      if (length(hb) == 0) {
        cat("If you are going to use Mac OS for scientific computing we recommend\nthat you install homebrew. Note: When asked for your system password\ncharacters are being entered, even if it seems the cursor isn't moving")
        inp <- readliner("Type y to install homebrew or n to stop the process: ")
        if (grepl("[yY]", inp)) {
          hb_string <- "tell application \"Terminal\"\n\tactivate\n\tdo script \"/usr/bin/ruby -e \\\"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\\\"\"\nend tell"
          cat(hb_string, file = "homebrew.scpt", sep = "\n")
          system("osascript homebrew.scpt", wait = TRUE)
        }
      } else {
        cat("Homebrew is already installed\n")
      }

      cat("\n\nInstallation on Mac complete. Close R and (re)start Rstudio\n\n")
    }
  } else {
    cat("\n\nThe install script is only partially supported on your OS\n\n")
    build()
  }
}

setwd(owd)

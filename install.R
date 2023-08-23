## install script for R(adiant) @ Rady School of Management
owd <- getwd()
options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))
repos <- c(
  RSM = "https://rsm-compute-01.ucsd.edu:4242/rsm-msba/__linux__/focal/latest",
  RSPM = "https://packagemanager.rstudio.com/all/__linux__/focal/latest",
  MINICRAN = "https://radiant-rstats.github.io/minicran/",
  CRAN = "https://cloud.r-project.org"
)

os <- Sys.info()["sysname"]
repos <- if (os == "Linux") repos else repos[c(3, 4)]
options(repos = repos)

build <- function(type = ifelse(os == "Linux", "source", "binary")) {
  update.packages(lib.loc = .libPaths()[1], ask = FALSE, type = type)

  ipkgs <- rownames(installed.packages())
  install <- function(x) {
    pkgs <- x[!x %in% ipkgs]
    if (length(pkgs) > 0) install.packages(pkgs, lib = .libPaths()[1], type = type)
  }
  install(c("radiant", "gitgadget", "miniUI", "webshot", "tinytex", "usethis", "svglite", "remotes"))

  if (!"radiant.update" %in% ipkgs) {
    ap <- available.packages(repos = repos)[, "Package"]
    if ("radiant.update" %in% ap) {
      install.packages("radiant.update", lib = .libPaths()[1], repos = repos)
      radiant.update::radiant.update()
    } else {
      ru <- try(remotes::install_github("radiant-rstats/radiant.update", upgrade = "never"))
      if (inherits("try-error", ru)) {
        print("radiant.update cannot be installed on your system at this time")
      } else {
        radiant.update::radiant.update()
      }
    }
  } else {
    radiant.update::radiant.update()
  }

  ## needed for windoze
  # pkgs <- new.packages(lib.loc = .libPaths()[1], repos = repos[c(1, 3)], ask = FALSE)
  # if (length(pkgs) > 0) {
  #   install.packages(pkgs, type = type)
  # }

  # see https://github.com/wch/webshot/issues/25#event-740360519
  if (is.null(webshot:::find_phantom())) webshot::install_phantomjs()
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
    lp <- .libPaths()[grepl("Documents", .libPaths())]
    if (grepl("(Prog)|(PROG)", Sys.getenv("R_HOME"))) {
      # rv <- paste(rv$major, rv$minor, sep = ".")
      cat(paste0("It seems you installed R in the Program Files directory. This can\ncause problems so we recommend you uninstall R, delete the Documents/R\ndirectory on your computer, and then re-install the latest version of R.\n\nThe most convenient way to install all required tools on Windows\nis to use the all-in-one-installer linked on the page below (see\nthe section on 'Installing Radiant on Windows')\n\n https://radiant-rstats.github.io/docs/install.html"), "\n\n")
    } else if (length(lp) > 0) {
      cat("Installing R-packages in the directory printed below often causes\nproblems on Windows. Please remove the 'Documents/R' directory\non your computer, close and restart R(studio), and then run the\ncommand below:\n\nsource(\"https://raw.githubusercontent.com/radiant-rstats/minicran/gh-pages/install.R\").\n\n")
      cat(paste0(lp, collapse = "\n"), "\n\n")
    } else {
      build()
      install.packages("installr")


      ## get rstudio - release
      page <- readLines("https://posit.co/download/rstudio-desktop/", warn = FALSE)
      pat <- "//download1.rstudio.org/electron/windows/RStudio-[0-9.]+.[0-9.]+.[0-9]+-[0-9]+.exe"
      URL <- paste0("https:", regmatches(page, regexpr(pat, page))[1])

      ## install
      installr::install.URL(URL, installer_option = "/S")

      wz <- suppressWarnings(system("where R", intern = TRUE))
      w7z <- suppressWarnings(system("where 7z", intern = TRUE))
      if (!grepl("zip", wz) && !grepl("7-Zip", w7z)) {
        # URL <- "http://rady.ucsd.edu/faculty/directory/nijs/pub/docs/radiant/7z1604-x64.exe"
        # URL <- "https://www.7-zip.org/a/7z1604-x64.exe"
        URL <- "https://www.7-zip.org/a/7z2200-x64.exe"
        installr::install.URL(URL)
        if (file.exists(file.path(Sys.getenv("ProgramFiles"), "7-Zip"))) {
          ## update path
          shell(paste0("setx PATH \"%PATH%;", paste0(Sys.getenv("ProgramFiles"), "\\7-Zip\"")))
        } else if (file.exists(file.path(Sys.getenv("ProgramFiles(x86)"), "7-Zip"))) {
          ## update path
          shell(paste0("setx PATH \"%PATH%;", paste0(Sys.getenv("ProgramFiles(x86)"), "\\7-Zip\"")))
        } else {
          cat("Couldn't find the location where 7-zip was installed. Please update the system path manually\n")
        }
      }

      cat("\nTo generate PDF reports in Radiant you will need TinyTex (or MikTex).\n")
      inp <- readliner("Proceed with the download and install of TinyTex? Press y or n and then press return: ")
      if (grepl("[yY]", inp)) {
        tinytex::install_tinytex()
      }
      cat("\n\nInstallation on Windows complete. Close R, (re)start Rstudio, and select 'Start radiant'\nfrom the Addins menu to get started\n\n")
    }
  } else if (os == "Darwin") {
    resp <- system("sw_vers -productVersion", intern = TRUE)
    if (as.numeric_version(resp) < as.numeric_version("10.9")) {
      cat("The version of OSX on your mac is no longer supported by R. You will need to upgrade the OS before proceeding\n\n")
    } else {
      build()
      ##  based on https://github.com/talgalili/installr/blob/82bf5b542ce6d2ef4ebc6359a4772e0c87427b64/R/install.R#L805-L813
      page <- readLines("https://posit.co/download/rstudio-desktop/", warn = FALSE)
      pat <- "//download1.rstudio.org/electron/macos/RStudio-[0-9.]+.[0-9.]+.[0-9]+.dmg"
      URL <- paste0("https:", regmatches(page, regexpr(pat, page))[1])

      setwd(tempdir())
      download.file(URL, "Rstudio.dmg")
      system("open Rstudio.dmg")
      cat("Please drag-and-drop the Rstudio image to the Applications folder on your Mac\n")

      ## moving Rstudio.app doesn't seem to work just yet
      # rstudio <- file.path("/Volumes", list.files("/Volumes", pattern = "^RStudio-*"), "RStudio.app")
      # system(paste0("cp -r ", rstudio, " /Applications", intern = TRUE))

      pl <- suppressWarnings(system("which pdflatex", intern = TRUE))
      if (length(pl) == 0) {
        cat("To generate PDF reports in Radiant (Report > Rmd) you will need TinyTex (or MacTex).")
        inp <- readliner("Proceed with the TinyTex download and install? Press y or n and then press return: ")
        if (grepl("[yY]", inp)) {
          tinytex::install_tinytex()
        }
      }
      cat("\n\nInstallation on Mac complete. Close R, (re)start Rstudio, and select 'Start radiant'\nfrom the Addins menu to get started\n\n")
    }
  } else {
    cat("\n\nThe install script only partially supports your OS\n")
    cat("You may prefer to use a docker image of Radiant and related software\nSee https://github.com/radiant-rstats/docker/blob/master/install/rsm-msba-linux.md for details\n\n")
    inp <- readliner("Do wish to proceed with the local install of Radiant and its dependencies? Press y or n and then press return: ")
    if (grepl("[yY]", inp)) {
      build()
      pl <- suppressWarnings(system("which pdflatex", intern = TRUE))
      if (length(pl) == 0) {
        cat("To generate PDF reports in Radiant (Report > Rmd) you will need TinyTex (or LaTex).")
        inp <- readliner("Proceed with the TinyTex download and install? Press y or n and then press return: ")
        if (grepl("[yY]", inp)) {
          tinytex::install_tinytex()
        }
      }
    }
  }
}

setwd(owd)

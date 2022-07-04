## install script for R(adiant) @ Rady School of Management (MBA)
owd <- getwd()
options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))
repos = c(
  MINICRAN = "https://radiant-rstats.github.io/minicran/",
  CRAN = "https://cloud.r-project.org"
)

options(repos = repos)

build <- function(type = "binary") {
  # bml
  install.packages(c('cmdstanr', 'posterior', 'bayesplot'), Ncpus = -1)

  # quarto
  install.packages('quarto', Ncpus = -1)

  # tidyverse
  install.packages(c('tidyverse', 'devtools', 'rmarkdown', 'vroom', 'gert', 'usethis'), Ncpus = -1)
  install.packages(c('dbplyr', 'DBI', 'dtplyr', 'RPostgres', 'RSQLite', 'fst'), Ncpus = -1)

  # radiant
  install.packages(c('radiant', 'gitgadget', 'miniUI', 'webshot', 'tinytex', 'svglite', 'readxl', 'writexl'), Ncpus=-1)
  install.packages(c('devtools', 'remotes', 'formatR', 'styler', 'reticulate', 'renv'), Ncpus=-1)
  install.packages(c('arrow', 'duckdb', 'fs', 'janitor', 'palmerpenguins', 'stringr', 'tictoc'), Ncpus=-1)
  install.packages(c('httpgd', 'languageserver'), Ncpus=-1)
  remotes::install_github("radiant-rstats/radiant.update", upgrade = "never")
  remotes::install_github("radiant-rstats/radiant.data", upgrade = "never")
  remotes::install_github("vnijs/DiagrammeR", upgrade = "never")
  remotes::install_github('vnijs/gitgadget')
}

rv <- R.Version()
rv <- paste(rv$major, rv$minor, sep = ".")

if (rv < "4.2.0") {
  cat("R-4.2.0 or later is required. Please install the latest\nversion of R from https://cloud.r-project.org/")
} else {

  os <- Sys.info()["sysname"]
  if (os == "Windows") {

    build()

    install.packages("installr")
    installr::install.Rtools()
    installr::install.git()

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

      cat("\n\nInstallation on Mac complete. Close R and (re)start Rstudio\n\n")
    }
  } else {
    cat("\n\nThe install script is only partially supported on your OS\n\n")
    build()
  }
}

setwd(owd)

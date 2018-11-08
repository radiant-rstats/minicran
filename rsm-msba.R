install_phantomjs <- function(version, baseURL) {

  if (!grepl("/$", baseURL))
    baseURL <- paste0(baseURL, "/")
  owd <- setwd(tempdir())
  on.exit(setwd(owd), add = TRUE)
  zipfile <- sprintf("phantomjs-%s-linux-%s.tar.bz2", version,
                     if (grepl("64", Sys.info()[["machine"]]))
                       "x86_64"
                     else "i686")
  webshot:::download(paste0(baseURL, zipfile), zipfile, mode = "wb")
  utils::untar(zipfile)
  zipdir <- sub(".tar.bz2$", "", zipfile)
  exec <- file.path(zipdir, "bin", "phantomjs")
  Sys.chmod(exec, "0755")
  dirs <- c("/usr/local/bin", "~/bin")
  for (destdir in dirs) {
    dir.create(destdir, showWarnings = FALSE)
    success <- file.copy(exec, destdir, overwrite = TRUE)
    if (success)
      break
  }
  unlink(c(zipdir, zipfile), recursive = TRUE)
  if (!success)
    stop("Unable to install PhantomJS to any of these dirs: ",
         paste(dirs, collapse = ", "))
  message("phantomjs has been installed to ", normalizePath(destdir))
  invisible()
}

build <- function(type = "source") {
  repos <- "https://radiant-rstats.github.io/minicran/"

  update.packages(
    lib.loc = .libPaths()[1],
    ask = FALSE,
    repos = repos,
    type = type
  )

  ipkgs <- installed.packages()
  install <- function(x) {
    if (!x %in% ipkgs) install.packages(x, repos = repos, type = type)
  }

  # resp <- sapply(
  #   c(
  #     "radiant", "radiant.update", "devtools", "roxygen2",
  #     "testthat", "gitgadget", "tinytex", "haven", "readxl",
  #     "writexl", "miniUI", "caret", "ranger", "gbm", "dbplyr",
  #     "DBI", "RSQLite", "RPostgreSQL", "pool", "usethis",
  #     "xgboost", "webshot", "reticulate"
  #   ),
  #   install
  # )

  pkgs <- new.packages(
    lib.loc = .libPaths()[1],
    repos = repos,
    type = type,
    ask = FALSE
  )
  if (length(pkgs) > 0) {
    install.packages(pkgs, repos = repos, type = type)
  }

  # see https://github.com/wch/webshot/issues/25#event-740360519
  # if (is.null(webshot:::find_phantom())) install_phantomjs()
  ws_args <- as.list(formals(webshot:::install_phantomjs))
  if (is.null(webshot:::find_phantom())) install_phantomjs(ws_args$version, ws_args$baseURL)
}

build()

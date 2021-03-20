# options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))
repos <- c(
  RSM = "https://rsm-compute-01.ucsd.edu:4242/rsm-msba/__linux__/focal/latest",
  RSPM = "https://packagemanager.rstudio.com/all/__linux__/focal/latest",
  RSMCRAN = "https://radiant-rstats.github.io/minicran/",
  CRAN = "https://cloud.r-project.org"
)

options(repos = repos)

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

build <- function(type = "binary", os = "") {
  repos_fun <- ifelse(os == "Linux", repos[1], repos[2])

  # update.packages(
  #   lib.loc = .libPaths()[1],
  #   ask = FALSE,
  #   repos = repos_fun,
  #   type = type
  # )

  # pkgs <- new.packages(
  #   lib.loc = .libPaths()[1],
  #   repos = repos_fun,
  #   type = type,
  #   ask = FALSE
  # )

  # update.packages(
  #   lib.loc = .libPaths()[1],
  #   ask = FALSE,
  #   repos = repos["RSPM"]
  # )

  pkgs <- new.packages(
    lib.loc = .libPaths()[1],
    repos = repos["RSMCRAN"],
    ask = FALSE
  )

  if (length(pkgs) > 0) {
    # install.packages(pkgs, repos = repos_fun, type = type)
    install.packages(pkgs, repos = repos["RSPM"])
  }

  # see https://github.com/wch/webshot/issues/25#event-740360519
  # if (is.null(webshot:::find_phantom())) install_phantomjs()
  ws_args <- as.list(formals(webshot:::install_phantomjs))
  if (is.null(webshot:::find_phantom())) install_phantomjs(ws_args$version, ws_args$baseURL)
}

os <- Sys.info()["sysname"]
if (os == "Linux") {
  build(type = "source", os = "Linux")
} else {
  build(type = "binary")
}

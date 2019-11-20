###############################################################
### RUN OUTSIDE OF RADIANT
###############################################################
# installing and loading packages
# repos <- c("file:///Users/vnijs/Desktop/Github/minicran/",

# install.packages("rprojroot")
minicran <- "https://radiant-rstats.github.io/minicran/"
repos <- c(
  "https://cloud.r-project.org",
  "https://cran.r-project.org",
  minicran
)
options(repos = c(CRAN = repos))

library(devtools)
library(miniCRAN)
source("selMakeRepo.R", local = TRUE)

# pth <- rstudioapi::getActiveProject()
pth <- rprojroot::find_root(rprojroot::has_file("README.md"))
pkgs <- c(
  "radiant", "miniUI", "webshot", "tinytex",
  "usethis", "radiant.update", "svglite", "formatR"
)

# check only files that needed updating or adding
# see PR https://github.com/RevolutionAnalytics/miniCRAN/pull/15/files
# not sure if ever merged
# pdb_local <- pkgAvail(repos = repos[1], type="source")
# pdb_remote <- pkgAvail(repos = repos[3:4], type="source")
# pkgList <- pkgDep(pkgs, availPkgs=pdb, repos=revolution, type="source", suggests=FALSE)

pkgs_src <- c(
  pkgs, "gitgadget", "devtools", "roxygen2", "caret", "ranger", "randomForest",
  "gbm", "dbplyr", "DBI", "RSQLite", "RPostgreSQL", "pool", "odbc", "xgboost",
  "png", "shinydashboard", "flexdashboard", "reticulate", "styler", "caTools",
  "tidyverse", "testthat", "tfestimators", "keras", "packrat", "sparklyr", "sparkxgb",
  "forge", "gganimate", "gifski", "here", "zipcode", "forcats", "future", "parsnip",
  "lime", "rsample", "infer", "yardstick", "tidyquant", "recipes", "vip", "kableExtra",
  "ggraph", "tidygraph", "bookdown", "lintr", "languageserver", "rprojroot", "iml",
  "xaringan", "magick", "arm", "rstan", "dtplyr", "renv", "RSelenium", "stringi"
)

# for Karsten
pkgs_src <- c(
  pkgs_src, "ggmap", "leaflet", "tm", "wordcloud", "rvest", "tidytext",
  "stm", "Hmisc", "SDMTools", "gtrendsR", "rgdal", "topicmodels", "rtweet",
  "pageviews", "googleAuthR"
)

# for Ken
pkgs_src <- c(
  pkgs_src, "stargazer", "lfe"
)

# building minicran for source packages
pkgList <- pkgDep(pkgs_src, repos = repos, type = "source", suggests = FALSE)
# download <- makeRepo(pkgs, path = pth, type = "source", Rversion = "3.6")
to_rm <- selMakeRepo(pkgList, path = pth, minicran, repos = repos, type = "source")

## only needed when a new major R-version comes out
# download <- makeRepo(pkgs, path = pth, type = "win.binary", Rversion = "3.7")
# download <- makeRepo(pkgs, path = pth, type = "mac.binary.el-capitan", Rversion = "3.7")

versions <- c("3.5", "3.6")
for (ver in versions) {
  ## building minicran for windows binaries
  pkgList <- pkgDep(pkgs, repos = repos, type = "win.binary", suggests = FALSE, Rversion = ver)
  to_rm <- selMakeRepo(pkgList, path = pth, minicran, repos = repos, type = "win.binary", Rversion = ver)

  ## building minicran for mac el-capitan binaries
  pkgList <- pkgDep(pkgs, repos = repos, type = "mac.binary.el-capitan", suggests = FALSE, Rversion = ver)
  to_rm <- selMakeRepo(pkgList, path = pth, minicran, repos = repos, type = "mac.binary.el-capitan", Rversion = ver)
}

## cleanup
library(dplyr)
library(magrittr)

win_dirs <- list.dirs("bin/windows/contrib")[-1]
mac_dirs <- list.dirs("bin/macosx/el-capitan/contrib")[-1]
pdirs <- c("src/contrib", win_dirs, mac_dirs)

for (pdir in pdirs) {
  print(pdir)
  old <- list.files(file.path(pth, pdir)) %>%
    data.frame(fn = ., stringsAsFactors = FALSE) %>%
    mutate(pkg_file = fn, pkg_name = strsplit(fn, "_") %>% sapply("[",1),
           pkg_version = strsplit(fn, "_") %>% sapply("[",2) %>% gsub("(.zip)|(.tar.gz)|(.tgz)","",.)) %>%
    filter(!is.na(pkg_version))
  old <- old[order(old$pkg_name, package_version(old$pkg_version)), ] %>%
    group_by(pkg_name) %>%
    summarise(old = n(), pkg_file_new = last(pkg_file), pkg_file_old = first(pkg_file)) %>%
    filter(old > 1) %T>% print(n = 100)

  if (nrow(old) > 0) {
    for (pf in old$pkg_file_old) {
      unlink(file.path(pth, pdir, pf))
    }
  }
}

## work-around for https://github.com/ramnathv/htmlwidgets/issues/348
# unlink("src/contrib/htmlwidgets*", force = TRUE)
# curl::curl_download("https://cran.r-project.org/src/contrib/Archive/htmlwidgets/htmlwidgets_1.3.tar.gz", destfile = "src/contrib/htmlwidgets_1.3.tar.gz")

## needed to update PACKAGES after deleting old versions
tools::write_PACKAGES("src/contrib/", type = "source")
sapply(win_dirs, tools::write_PACKAGES, type = "win.binary")
sapply(mac_dirs, tools::write_PACKAGES, type = "mac.binary")

## push to github
rstudioapi::documentSaveAll()
system("git add --all .")
mess <- paste0("update for: ", paste0(pkgs, collapse = ", "), " (", format(Sys.Date(), format = "%m-%d-%Y"), ")")
system(paste0("git commit -m '", mess, "'"))
system("git push")

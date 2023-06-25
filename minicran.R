###############################################################
### RUN OUTSIDE OF RADIANT
###############################################################
# installing and loading packages
# repos <- c("file:///Users/vnijs/Desktop/Github/minicran/",

# install.packages("rprojroot")
# install.packages("dplyr")
# install.packages("magrittr")
# install.packages("devtools")

# use locally build miniCRAN so the latest R versions work
# install.packages("miniCRAN")

minicran <- "https://radiant-rstats.github.io/minicran/"
repos <- c(
  "https://cloud.r-project.org",
  "https://cran.r-project.org",
  minicran
)

options(repos = c(CRAN = repos))
# options(repos = c(CRAN = minicran))

library(devtools)
library(miniCRAN)
source("selMakeRepo.R", local = TRUE)

pth <- rprojroot::find_root(rprojroot::has_file("README.md"))

pkgs <- c(
  "radiant", "miniUI", "webshot", "tinytex",
  "usethis", "svglite", "ranger", "xgboost",
  "pdp", "patchwork", "lobstr", "remotes",
  "bslib", "png", "quarto", "vip"
)

# check only files that needed updating or adding
# see PR https://github.com/RevolutionAnalytics/miniCRAN/pull/15/files
# not sure if ever merged
# pdb_local <- pkgAvail(repos = repos[1], type="source")
# pdb_remote <- pkgAvail(repos = repos[3:4], type="source")
# pkgList <- pkgDep(pkgs, availPkgs=pdb, repos=revolution, type="source", suggests=FALSE)

pkgs_src <- c(
  pkgs, "gitgadget", "ranger", "dbplyr", "DBI", "RSQLite", "RPostgres", "pool",
  "odbc", "xgboost", "png", "reticulate", "styler", "caTools",
  "tidyverse", "rsample", "vip", "kableExtra", "languageserver", "iml",
  "xaringan", "magick", "stringi", "RhpcBLASctl", "V8"
)

# for Karsten
pkgs_src <- c(
  pkgs_src, "ggmap", "leaflet", "tm", "wordcloud", "rvest", "tidytext",
  "stm", "Hmisc", "SDMTools", "gtrendsR", "rgdal"
)

# for Ken
# pkgs_src <- c(
#   pkgs_src, "stargazer", "lfe"
# )

# for Terry
pkgs_src <- c(
  pkgs_src, "simmer",  "simmer.plot", "EnvStats", "ggfortify",
  "linprog", "lpSolve"
)

## if you have removed a radiant dependency **but**
## the change is not yet on CRAN use the below as repo
# repos <- minicran
# pkgs <- pkgs_src <- c("ranger", "xgboost", "pdp", "patchwork", "clustMixType")

clean_pkgs <- function(pkl) {
  setdiff(pkl, c("Gmedian", "RSpectra"))
}

# building minicran for source packages
pkgList <- pkgDep(pkgs_src, repos = repos, type = "source", suggests = FALSE)
to_rm <- selMakeRepo(clean_pkgs(pkgList), path = pth, minicran, repos = repos, type = "source")

## only needed when a new major R-version comes out
# download <- makeRepo(pkgs, path = pth, type = "win.binary", Rversion = "4.3")
# download <- makeRepo(pkgs, path = pth, type = "mac.binary", Rversion = "4.3")

# See https://github.com/andrie/miniCRAN/issues/142
# download <- makeRepo(pkgs, path = pth, type = "mac.binary.big-sur-arm64", Rversion = "4.3")

pkgs <- unique(c(pkgs, c("GPArotation", "pdp")))

versions <- c("4.0", "4.1", "4.2", "4.3")
for (ver in versions) {
  # ver <- versions
  ## building minicran for windows binaries
  pkgList <- pkgDep(pkgs, repos = repos, type = "win.binary", suggests = FALSE, Rversion = ver)
  to_rm <- selMakeRepo(clean_pkgs(pkgList), path = pth, minicran, repos = repos, type = "win.binary", Rversion = ver)
  sapply(setdiff(names(to_rm), "gitgadget"), function(x) unlink(file.path(pth, "bin/windows/contrib", ver, paste0(x, "_*")), force = TRUE))

  ## building minicran for mac el-capitan binaries
  pkgList <- pkgDep(pkgs, repos = repos, type = "mac.binary", suggests = FALSE, Rversion = ver)
  to_rm <- selMakeRepo(clean_pkgs(pkgList), path = pth, minicran, repos = repos, type = "mac.binary", Rversion = ver)
  sapply(setdiff(names(to_rm), "gitgadget"), function(x) unlink(file.path(pth, "bin/macosx/contrib", ver, paste0(x, "_*")), force = TRUE))

  if (ver >= "4.1") {
    ## building minicran for mac arm64 binaries
    pkgList <- pkgDep(pkgs, repos = repos, type = "mac.binary.big-sur-arm64", suggests = FALSE, Rversion = ver)
    to_rm <- selMakeRepo(clean_pkgs(pkgList), path = pth, minicran, repos = repos, type = "mac.binary.big-sur-arm64", Rversion = ver)
    sapply(setdiff(names(to_rm), "gitgadget"), function(x) unlink(file.path(pth, "bin/macosx/big-sur-arm64/contrib", ver, paste0(x, "_*")), force = TRUE))
  }
}


# https://cran.r-project.org/bin/macosx/big-sur-arm64/contrib/4.1/radiant_1.3.2.tgz

# pkgList <- pkgDep("radiant", repos = repos, type = "mac.binary", suggests = FALSE, Rversion = "4.0")
# cat(paste0("pkgs <- c('", paste0(pkgList, collapse = "', '"), "')", collapse = ","), file = "pkgs.R")

# repos <- c(
#   "https://cloud.r-project.org",
#   "https://cran.r-project.org"
# )
#
# ## building minicran for mac el-capitan binaries
# pkgList <- pkgDep(pkgs, repos = repos, type = "mac.binary", suggests = FALSE, Rversion = ver)
# to_rm <- selMakeRepo(clean_pkgs(pkgList), path = pth, minicran, repos = repos, type = "mac.binary", Rversion = ver)
# sapply(setdiff(names(to_rm), "gitgadget"), function(x) unlink(file.path(pth, "bin/macosx/contrib", ver, paste0(x, "_*")), force = TRUE))

## cleanup
library(dplyr)
library(magrittr)

win_dirs <- list.dirs("bin/windows/contrib")[-1]
mac_dirs <- list.dirs("bin/macosx/el-capitan/contrib")[-1]
mac_dirs <- c(mac_dirs, list.dirs("bin/macosx/contrib")[-1])
mac_dirs <- c(mac_dirs, list.dirs("bin/macosx/big-sur-arm64/contrib")[-1])
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


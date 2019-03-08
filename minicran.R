###############################################################
### RUN OUTSIDE OF RADIANT
###############################################################
# installing and loading packages
# repos <- c("file:///Users/vnijs/Desktop/Github/minicran/",

minicran <- "https://radiant-rstats.github.io/minicran/"
repos <- c(
  minicran,
  "https://cloud.r-project.org",
  "https://cran.r-project.org"
)
# repos <- c(
#   "https://cloud.r-project.org",
#   "https://cran.r-project.org",
#   minicran
# )
options(repos = c(CRAN = repos))

library(devtools)
library(miniCRAN)
source("selMakeRepo.R", local = TRUE)

pth <- rstudioapi::getActiveProject()
pkgs <- c(
  "radiant", "miniUI", "webshot", "tinytex",
  "usethis", "radiant.update", "svglite"
)

## check only files that needed updating or adding
## see PR https://github.com/RevolutionAnalytics/miniCRAN/pull/15/files
## not sure if ever merged
# pdb_local <- pkgAvail(repos = repos[1], type="source")
# pdb_remote <- pkgAvail(repos = repos[3:4], type="source")
# pkgList <- pkgDep(pkgs, availPkgs=pdb, repos=revolution, type="source", suggests=FALSE)

pkgs_src <- c(
  pkgs, "gitgadget", "devtools", "roxygen2", "caret", "ranger", "randomForest",
  "gbm", "dbplyr", "DBI", "RSQLite", "RPostgreSQL", "pool", "odbc", "xgboost",
  "png", "shinydashboard", "flexdashboard", "reticulate", "styler", "caTools",
  "tidyverse", "testthat", "tfestimators", "keras", "packrat", "sparklyr",
  "gganimate", "gifski", "here", "zipcode", "forcats", "future", "parsnip",
  "lime", "rsample", "infer", "yardstick", "tidyquant", "recipes", "vip", "kableExtra"
)

## for khansen
## gtrendsR will be updated to the github version in the radiant docker
pkgs_src <- c(
  pkgs_src, "ggmap", "leaflet", "tm", "wordcloud", "rvest", "tidytext",
  "stm", "Hmisc", "SDMTools", "gtrendsR", "rgdal", "topicmodels"
)

## anything to remove?
pkgs_rem <- c(
  "checkmate", "magick", "matrixStats", "pander", "pryr", "rapportools",
  "summarytools", "rstan", "greta", "rstanarm", "rstantools", "listenv",
  "shinystan", "tidymodels", "tidyposterior", "tidypredict"
)

# building minicran for source packages
pkgList <- pkgDep(pkgs_src, repos = repos, type = "source", suggests = FALSE)
#length(pkgList)
#pkgList <- setdiff(pkgList, pkgs_rem)
#length(pkgList)
# pkgs_rem[pkgs_rem %in% pkgList]
to_rm <- selMakeRepo(pkgList, path = pth, minicran, repos = repos, type = "source")

# building minicran for windows binaries
pkgList <- pkgDep(pkgs, repos = repos, type = "win.binary", suggests = FALSE, Rversion = "3.4")
length(pkgList)
pkgList <- setdiff(pkgList, pkgs_rem)
length(pkgList)
to_rm <- selMakeRepo(pkgList, path = pth, minicran, repos = repos, type = "win.binary", Rversion = "3.4")

# building minicran for windows binaries
pkgList <- pkgDep(pkgs, repos = repos, type = "win.binary", suggests = FALSE, Rversion = "3.5")
length(pkgList)
pkgList <- setdiff(pkgList, pkgs_rem)
length(pkgList)
to_rm <- selMakeRepo(pkgList, path = pth, minicran, repos = repos, type = "win.binary", Rversion = "3.5")

# building minicran for mac el-capitan binaries
pkgList <- pkgDep(pkgs, repos = repos, type = "mac.binary.el-capitan", suggests = FALSE, Rversion = "3.4")
length(pkgList)
pkgList <- setdiff(pkgList, pkgs_rem)
length(pkgList)
to_rm <- selMakeRepo(pkgList, path = pth, minicran, repos = repos, type = "mac.binary.el-capitan", Rversion = "3.4")

# building minicran for mac el-capitan binaries
pkgList <- pkgDep(pkgs, repos = repos, type = "mac.binary.el-capitan", suggests = FALSE, Rversion = "3.5")
length(pkgList)
pkgList <- setdiff(pkgList, pkgs_rem)
length(pkgList)
cat(paste0("pkgs <- c('", paste0(pkgList, collapse = "', '"), "')"), file = "pkgs.R")
to_rm <- selMakeRepo(pkgList, path = pth, minicran, repos = repos, type = "mac.binary.el-capitan", Rversion = "3.5")

library(dplyr)
library(magrittr)

pdirs <- c(
  "src/contrib",
  "bin/windows/contrib/3.4",
  "bin/windows/contrib/3.5",
  "bin/macosx/el-capitan/contrib/3.4",
  "bin/macosx/el-capitan/contrib/3.5"
)

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

## needed to update PACKAGES after deleting old versions
tools::write_PACKAGES("bin/windows/contrib/3.4/", type = "win.binary")
tools::write_PACKAGES("bin/windows/contrib/3.5/", type = "win.binary")
tools::write_PACKAGES("bin/macosx/el-capitan/contrib/3.4/", type = "mac.binary")
tools::write_PACKAGES("bin/macosx/el-capitan/contrib/3.5/", type = "mac.binary")
tools::write_PACKAGES("src/contrib/", type = "source")

## push to github
rstudioapi::documentSaveAll()
system("git add --all .")
mess <- paste0("update for: ", paste0(pkgs, collapse = ", "), " (", format(Sys.Date(), format = "%m-%d-%Y"), ")")
system(paste0("git commit -m '", mess, "'"))
system("git push")

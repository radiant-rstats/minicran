## build el-capitan from source
# app <- "dplyr_0.7.2.tar.gz"
# app_mac <- sub("tar.gz","tgz", app)
# path <- "src/contrib"
# system(paste0("R CMD INSTALL --build ", file.path(path, app)))
# file.copy(app_mac, "bin/macosx/el-capitan/contrib/3.4/")
# file.remove(app_mac)

## build for mac
path <- "../"
curr <- getwd(); setwd(path)
build_app <- function(app) {
  f <- devtools::build(app)
  system(paste0("R CMD INSTALL --build ", f))
}
sapply("rstudioapi", build_app)
setwd(curr)


## make sure to restart R(studio) before you run this script
inst <- installed.packages()
ind <- inst[,"Priority"] %in% c("base","recommended")
inst <- rownames(inst)
base <- inst[ind]
rem <- base::setdiff(inst, base)

## remove all but the base packages
remove.packages(rem)

cmd <- "source('https://raw.githubusercontent.com/radiant-rstats/minicran/gh-pages/update.R'); counter = 'once already'"
ret <- .rs.restartR(cmd)

# sudo su -c "R -e \"install.packages('radiant.update', repos = 'https://radiant-rstats.github.io/minicran/')\""
# sudo su -c "R -e \"source('https://raw.githubusercontent.com/radiant-rstats/minicran/gh-pages/update.R')\""

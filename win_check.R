ret <- suppressPackageStartupMessages(require("radiant"))
if (ret) {
  message("\nRadiant update successfully completed\n")
} else {
  message("\nRadiant update attempt was unsuccessful. Please copy the source command below, restart R(studio), and then paste the command into the R(studio) console and press return. If the update is still not successful, please send an email to radiant@rady.ucsd.edu with screen shots of the output shown in R(studio).\n\nsource('https://raw.githubusercontent.com/radiant-rstats/minicran/gh-pages/update.R')\n\n-------------------------------------------------------------------------------------\n")
}

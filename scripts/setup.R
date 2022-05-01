# Nomes dos pacotes utilizados por esse pipeline
pacotes <- c('optparse', 'foreign', 'dplyr', 'purrr', 'vroom', 'flexdashboard',
             'ggplot2', 'esquisse', 'sf', 'ggspatial', 'devtools', 'lubridate',
             'plotly', 'scales')

# Instale os pacotes que ainda não foram instalados
pacotes_ja_instalados <- pacotes %in% rownames(installed.packages())

message('Checando se existem pacotes R necessários não instalados...')

if (any(pacotes_ja_instalados == FALSE)) {
  install.packages(pacotes[!pacotes_ja_instalados],
                   repos = "http://cran.us.r-project.org")
} else {
  message('Todos os pacotes R necessários já estão instalados.\n')
}

devtools::install_github("ipeaGIT/geobr", subdir = "r-package")

if (any(c(pacotes, 'geobr') %in% rownames(installed.packages()) == FALSE)) {
  stop("Erro: Não foi possível instalar todos os pacotes necessários.")
}
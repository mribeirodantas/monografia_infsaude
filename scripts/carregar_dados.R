# #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#
#                        Copyright (c) 2022
#            Marcel Ribeiro-Dantas <marcel.ribeiro-dantas@curie.fr>
#
# This script is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #

suppressWarnings(library(optparse))
suppressWarnings(library(foreign))
suppressPackageStartupMessages(
  suppressWarnings(
    library(dplyr)
  )
)
suppressWarnings(library(purrr))
suppressWarnings(library(vroom))

# Os dados podem ser baixados nos links abaixo.
# INCA
#   RHC (Registro Hospitalar de Câncer)
#   https://irhc.inca.gov.br/RHCNet/visualizaTabNetExterno.action
# IBGE
#   Estatísticas Sociais: microdados_pesquisa_sobre_padroes_de_vida.zip
#   https://www.ibge.gov.br/estatisticas/downloads-estatisticas.html
#   Indicadores Sociais
#     Assistencia_medico_sanitaria (2002, 2005, 2009)
#       Sintese de Indicadores Sociais
#         


# Parsing de argumentos de linha de comando -------------------------------


option_list = list(
  make_option(c("-i", "--input"), type="character", default=NULL, 
              help="Caminho para o arquivo do RHC que você quer carregar", metavar="character"),
  make_option(c("-t", "--traduzir"), action="store_true", 
              help="Utilize o dicionário de dados para traduzir colunas/valores"),
  make_option(c("-c", "--cod_ibge"), action="store_true", 
              help="Traduza o código de municípios do IBGE para o nome dos municípios")
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

if (is.null(opt$input)){
  print_help(opt_parser)
  stop("Você precisa informar um caminho para o arquivo com o parâmetro -i ou --i", call.=FALSE)
}

if (!file.exists(opt$input)) {
  stop('O arquivo compactado não foi encontrado. Você informou o nome correto?')
} else if (tools::file_ext(opt$input) != 'zip') {
  stop('O arquivo informado não tem a extensão zip. Você baixou o arquivo correto?')
}

# Organizando os arquivos do RHC na árvore de diretórios ------------------

dir.create('dados', showWarnings = FALSE)
fs::file_move(path = opt$input,
              new_path = 'dados/'
              )
setwd(file.path('dados'))
utils::unzip(zipfile = basename(opt$input),
             exdir = '.')
# fs::file_delete(basename(opt$input))

inca_raw_data <-
  list.files(path = '.', pattern = '*.dbf') |>
  # Do not convert character vectors into factors
  purrr::map_df(~foreign::read.dbf(., as.is = TRUE)) |>
  vroom::vroom_write(file = 'inca.tsv',
                     delim = '\t')
if (isTRUE(opt$cod_ibge)) {
  cod_mun_ibge <- read.csv2(file = '../documentos/cod_mun_ibge.csv',
                            sep = ',')
}

if (isTRUE(opt$traduzir)) {
  # Traduzindo os valores
  inca_raw_data <- inca_raw_data |>
    dplyr::mutate(ALCOOLIS =
                    dplyr::recode(ALCOOLIS,
                                  `1`="Nunca",
                                  `2`="Ex-consumidor",
                                  `3`="Sim",
                                  `8`="Não se aplica",
                                  .default = NA_character_
                                  )
                  ) |>
    dplyr::mutate(TABAGISM =
                    dplyr::recode(TABAGISM,
                                  `1`="Nunca",
                                  `2`="Ex-consumidor",
                                  `3`="Sim",
                                  `8`="Não se aplica",
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(ANOPRIDI =
                    dplyr::recode(ANOPRIDI,
                                  `8888`=NA_character_,
                                  `9999`=NA_character_
                    )
    ) |>
    dplyr::mutate(BASDIAGSP =
                    dplyr::recode(BASDIAGSP,
                                  `1`="Exame clinico",
                                  `2`="Recursos auxiliares microscópicos",
                                  `3`="Confirmação miscroscópica",
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(DIAGANT=
                    dplyr::recode(DIAGANT,
                                  `1`="Sem diagnostico, sem tratamento",
                                  `2`="Com diagnostico, sem tratamento",
                                  `3`="Com diagnositco, com tratamento",
                                  `4`="Outros",
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(TPCASO =
                    dplyr::recode(TPCASO,
                                  `1`="Analítico",
                                  `2`="Não analítico"
                    )
    ) |>
    dplyr::mutate(SEXO =
                    dplyr::recode(SEXO,
                                  `1`="Masculino",
                                  `2`="Feminino",
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(IDADE = as.integer(IDADE)) |>
    dplyr::mutate(IDADE = case_when(
      IDADE <= -1 ~ NA_integer_,
      IDADE %in% c(888, 999) ~ NA_integer_,
      TRUE ~ IDADE,
    )) |>
    dplyr::mutate(RACACOR =
                    dplyr::recode(RACACOR,
                                  `1`="Branca",
                                  `2`="Preta",
                                  `3`="Amarela",
                                  `4`="Parda",
                                  `5`="Indígena",
                                  `9`=NA_character_,
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(INSTRUC =
                    dplyr::recode(INSTRUC,
                                  `1`="Nenhuma",
                                  `2`="Fundamental incompleto",
                                  `3`="Fundamental completo",
                                  `4`="Nível médio",
                                  `5`="Nível superior incompleto",
                                  `6`="Nível superior completo",
                                  `9`=NA_character_,
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(HISTFAMC =
                    dplyr::recode(HISTFAMC,
                                  `1`="Sim",
                                  `2`="Não",
                                  `9`=NA_character_,
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(ORIENC =
                    dplyr::recode(ORIENC,
                                  `1`="SUS",
                                  `2`="Não SUS",
                                  `3`="Veio por conta própria",
                                  `8`="Não se aplica",
                                  `9`=NA_character_,
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(EXDIAG =
                    dplyr::recode(EXDIAG,
                                  `1`="Exame clínico e patologia clínica",
                                  `2`="Exames por imagem",
                                  `3`="Endoscopia e cirurgia exploradora",
                                  `4`="Anatomia patológica",
                                  `5`="Marcadores tumorais",
                                  `8`="Não se aplica",
                                  `9`=NA_character_,
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(ESTCONJ =
                    dplyr::recode(ESTCONJ,
                                  `1`="Solteiro",
                                  `2`="Casado",
                                  `3`="Viúvo",
                                  `4`="Separado judicialmente",
                                  `5`="União consensual",
                                  `9`=NA_character_,
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(BASMAIMP =
                    dplyr::recode(BASMAIMP,
                                  `1`="Clínica",
                                  `2`="Pesquisa clínica",
                                  `3`="Exame por imagem",
                                  `4`="Marcadores tumorais",
                                  `5`="Citologia",
                                  `6`="Histologia da metástase",
                                  `7`="Histologia do tumor primário",
                                  `9`=NA_character_,
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(LATERALI =
                    dplyr::recode(LATERALI,
                                  `1`="Direita",
                                  `2`="Esquerda",
                                  `3`="Bilateral",
                                  `8`="Não se aplica",
                                  `9`=NA_character_,
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(MAISUMTU =
                    dplyr::recode(MAISUMTU,
                                  `1`="Não",
                                  `2`="Sim",
                                  `3`="Duvidoso",
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(RZNTR =
                    dplyr::recode(RZNTR,
                                  `1`="Recusa do tratamento",
                                  `2`="Tratamento realizado fora",
                                  `3`="Doença avançada, falta de condições clínicas ou outras doenças associadas",
                                  `4`="Abandono do tratamento",
                                  `5`="Complicações de tratamento",
                                  `6`="Óbito",
                                  `7`="Outras razões",
                                  `8`="Não se aplica",
                                  .default = NA_character_
                    )
    ) |>
    dplyr::mutate(PRITRATH =
                    dplyr::recode(RZNTR,
                                  `1`="Recusa do tratamento",
                                  `2`="Tratamento realizado fora",
                                  `3`="Doença avançada, falta de condições clínicas ou outras doenças associadas",
                                  `4`="Abandono do tratamento",
                                  `5`="Complicações de tratamento",
                                  `6`="Óbito",
                                  `7`="Outras razões",
                                  `8`="Não se aplica",
                                  .default = NA_character_
                    )
    )
    
    if (isTRUE(opt$cod_ibge)) {
      cod_mun_ibge_MUUH <- cod_mun_ibge |>
        rename(MUUH = `Código.Município.Completo`) |>
        mutate(MUUH = as.integer(MUUH))
      cod_mun_ibge_PROCEDEN <- cod_mun_ibge |>
        rename(PROCEDEN = `Código.Município.Completo`) |>
        mutate(PROCEDEN = as.integer(PROCEDEN))
      
      inca_raw_data |>
        mutate(MUUH = as.integer(MUUH)) |>
        left_join(cod_mun_ibge_MUUH, by='MUUH') |>
        mutate(MUUH = Nome_Município) |>
        select(-c(Nome_Município)) -> inca_raw_data
      inca_raw_data |>
        mutate(PROCEDEN = as.integer(PROCEDEN)) |>
        left_join(cod_mun_ibge_PROCEDEN, by='PROCEDEN') |>
        mutate(PROCEDEN = Nome_Município) |>
        select(-c(Nome_Município)) -> inca_raw_data
    }
    
    
    # TODO
    # Ler de arquivo para Clinicas, CNES, LOCTUDET (CID-O, 3), LOCTUPRI (CID-O, 4), LOCTUPRO (CID-O, 4), TIPOHOST (CID-O), TNM (TNM), PTNM/ESTADIAM/ESTADIAG/OUTROESTA 
    
    
  # Traduzindo o nome das colunas
  system(paste0("awk '$1 ~ /^[T|S|L]/' rhcGeral.def |",
                " sed 's/^[T|S|L]//g' | awk -F ',' '{print $1, $2}' |",
                " sed -e's/   */  /g' | uniq > nomes_colunas"))
  nomes_colunas <- vroom::vroom('nomes_colunas',
                                delim = '  ',
                                col_names = c('longo', 'curto'),
                                show_col_types = FALSE)
  nomes_colunas <- nomes_colunas |>
    dplyr::distinct(curto, .keep_all = TRUE) |> # e.g. IDADE
    dplyr::distinct(longo, .keep_all = TRUE) # e.g. Historico familiar
  colnames(inca_raw_data) <- dplyr::recode(
    colnames(inca_raw_data), 
    !!!setNames(as.character(nomes_colunas$longo), nomes_colunas$curto)
  )
  # Converter datas para tipo de dado Date
  inca_raw_data <- inca_raw_data |>
    dplyr::mutate(`Ano 1 tratamento` = as.integer(`Ano 1 tratamento`)) |>
    dplyr::mutate(`Ano triagem` = as.integer(`Ano triagem`)) |>
    dplyr::mutate(`Ano diagnostico` = as.integer(`Ano diagnostico`)) |>
    dplyr::mutate(`Ano de 1 consulta` = as.integer(`Ano de 1 consulta`)) |>
    dplyr::mutate(DTDIAGNO = as.Date(DTDIAGNO, "%d/%m/%Y")) |>
    dplyr::mutate(DTTRIAGE = as.Date(DTTRIAGE, "%d/%m/%Y")) |>
    dplyr::mutate(DATAINITRT = as.Date(DATAINITRT, "%d/%m/%Y")) |>
    dplyr::mutate(DATAOBITO = as.Date(DATAOBITO, "%d/%m/%Y")) |>
    dplyr::mutate(DATAPRICON = as.Date(DATAPRICON, "%d/%m/%Y")) |>
    select(-c(VALOR_TOT))
} else {
  # Converter datas para tipo de dado Date
  inca_raw_data <- inca_raw_data |>
    dplyr::mutate(DTINITRT = as.integer(DTINITRT)) |>
    dplyr::mutate(ANTRI = as.integer(ANTRI)) |>
    dplyr::mutate(ANOPRIDI = as.integer(ANOPRIDI)) |>
    dplyr::mutate(DTPRICON = as.integer(DTPRICON)) |>
    dplyr::mutate(DTDIAGNO = as.Date(DTDIAGNO, "%d/%m/%Y")) |>
    dplyr::mutate(DTTRIAGE = as.Date(DTTRIAGE, "%d/%m/%Y")) |>
    dplyr::mutate(DATAINITRT = as.Date(DATAINITRT, "%d/%m/%Y")) |>
    dplyr::mutate(DATAOBITO = as.Date(DATAOBITO, "%d/%m/%Y")) |>
    dplyr::mutate(DATAPRICON = as.Date(DATAPRICON, "%d/%m/%Y")) |>
    dplyr::select(-c(VALOR_TOT))
}

suppressWarnings(rm(cod_mun_ibge, cod_mun_ibge_MUUH, cod_mun_ibge_PROCEDEN, nomes_colunas))

# Salvar arquivo processado
saveRDS(inca_raw_data,
        file = 'INCA.rds')
message("Carregamento de dados concluído.")

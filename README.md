# Baixando essa ferramenta

git clone https://github.com/mribeirodantas/monografia_infsaude.git
cd monografia_infsaude

# Checando e instalando dependências
Rscript scripts/setup.R

# Carregando os dados
Baixe os dados a partir do portal [Integrador RHC do INCA](https://irhc.inca.gov.br/RHCNet/visualizaTabNetExterno.action).

Abra um aplicativo de linha de comando (terminal) e execute o script carregar_dados.R que se encontra na pasta script, informando onde o arquivo baixado se encontra. A recomendação é que o arquivo esteja na pasta dessa ferramenta.
É interessante utilizar o parâmetro -t (para traduzir o nome de algumas variáveis) e -c para substituir os códigos de município pelos nomes dos municípios. Os modelos de painel foram construídos levando em consideração que esses
parâmetros foram utilizados, portanto é indicado que voce execute a linha abaixo com os parâmetros -t e -c (ao menos o -t).

```
Rscript scripts/carregar_dados.R -i arquivo.zip -t -c
```

Uma vez isso feito, você deve abrir os arquivos RMarkdown dos modelos de painel com o RStudio (de preferência) de modo a gerar os painéis. Caso você queira trabalhar com os dados da base de Registros Hospitalares de Câncer, basta
carregar o arquivo INCA.rds na pasta dados, como é feito pelos arquivos do modelo. O arquivo HTML gerado na pasta script pode ser compartilhado e poderá ser carregado em qualquer computador com um navegador de internet, sem
necessidade de conexão com a internet.

# esquisse
Caso queira criar mais gráficos, descomente as primeiras linhas dos arquivos de modelo. Ao utilizar o esquisse, você poderá criar gráficos utilizando basicamente o seu mouse.

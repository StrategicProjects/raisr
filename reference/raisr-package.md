# raisr: Access 'RAIS' Microdata from the Brazilian Ministry of Labour

Download and read the public, non-identified microdata of the 'RAIS'
(Relação Anual de Informações Sociais), the annual census of formal
employment relationships and establishments published by the Brazilian
Ministry of Labour and Employment through the 'PDET' FTP server
\<ftp://ftp.mtps.gov.br/pdet/microdados/RAIS/\>. Lists the years and
archives available on the server, resolves which regional or state
archive holds a given state, downloads it with an idempotent local
cache, and reads the '7z' archives as a stream, filtering by state and
selecting columns before anything is kept in memory, so that a single
state can be extracted from a regional file of tens of millions of
records. Handles the two header generations of the files (up to the
'RAIS' 2022 and from the 'RAIS' 2023 onwards) with the same normalized
column names, provides the official record layout and a helper to
consolidate the employment stock, admissions, separations and December
payroll.

## See also

Useful links:

- <https://github.com/StrategicProjects/raisr>

- <https://strategicprojects.github.io/raisr/>

- Report bugs at <https://github.com/StrategicProjects/raisr/issues>

## Author

**Maintainer**: Andre Leite <leite@castlab.org>
([ORCID](https://orcid.org/0000-0002-4718-9766))

Authors:

- Andre Leite <leite@castlab.org>
  ([ORCID](https://orcid.org/0000-0002-4718-9766))

- Marcos Wasiliew <marcos.wasiliew@sepe.pe.gov.br>

- Hugo Vasconcelos <hugo.vasconcelos@ufpe.br>
  ([ORCID](https://orcid.org/0000-0001-6249-0920))

- Carlos Amorim <carlos.agaf@ufpe.br>
  ([ORCID](https://orcid.org/0000-0001-6315-8305))

- Diogo Bezerra <diogo.bezerra@ufpe.br>
  ([ORCID](https://orcid.org/0000-0002-1216-8674))

- Júlia Nascimento Barreto <juliabarreto@gd.seplag.pe.gov.br>

# ADR 002: Usar psycopg (v3) como driver do PostgreSQL

**Status:** Aceito
**Date:** 2026-08-07

## Contexto

O projeto precisa de um driver para PostgreSQL em Python — usado tanto pelo
Alembic na aplicação de migrações quanto, mais tarde, pela API na consulta de
dados.

`psycopg2-binary` é a escolha convencional: é o que a maioria dos tutoriais
assume, o que a maioria dos projetos existentes usa e o que a documentação do
SQLAlchemy usa por padrão. Por isso, foi o primeiro driver instalado.

Durante a configuração inicial do Alembic, a conexão por meio de `psycopg2`
falhou na máquina de desenvolvimento (Windows) com um `UnicodeDecodeError`
na decodificação de uma mensagem retornada pelo servidor. A falha ocorreu dentro
do próprio driver, antes que qualquer código da aplicação pudesse tratá-la, e
não estava relacionada às credenciais de conexão — a mesma conexão passou a
funcionar assim que o driver foi substituído.

A causa mais provável é que o servidor local de PostgreSQL emita mensagens em
português, e o `psycopg2` no Windows decodifique essas mensagens usando uma
codificação diferente dos bytes realmente retornados. Esse é um problema
específico do ambiente, e não uma falha na configuração do projeto, mas faz com
que o `psycopg2` seja impraticável nessa máquina sem soluções alternativas.

## Decisão

Usar `psycopg` versão 3 (instalado como `psycopg[binary]`) como driver do
PostgreSQL, com URLs de conexão usando o esquema `postgresql+psycopg://`.

## Justificativa

Substituir o driver resolveu o problema diretamente, sem necessidade de
workarounds, o que pesa mais do que seguir a convenção mais comum — um driver
que não consegue conectar na máquina principal de desenvolvimento não é uma
opção viável como padrão, independentemente de quão amplamente seja usado em
outros lugares.

Além de corrigir o problema imediato, o `psycopg` v3 é a linha ativamente
desenvolvida da biblioteca: a v2 continua mantida, mas já não é o foco de novos
trabalhos. Iniciar um novo projeto na v3 evita uma migração posterior.

### Alternativas consideradas

- **Manter o psycopg2 e forçar a codificação do cliente** — configurar
  `PGCLIENTENCODING` ou ajustar o locale do sistema talvez funcionasse, mas
  tornaria o projeto dependente de configuração de ambiente não capturada no
  repositório e provavelmente reapareceria em qualquer outra máquina Windows.
- **Manter o psycopg2 e desenvolver dentro de um container** — rodar o Alembic
  dentro de um container Linux contornaria o problema específico de decodificação
  no Windows. Isso continua sendo uma opção razoável, mas torna o ciclo diário
  mais lento para um problema que a troca de driver resolve de imediato.

## Consequências

### Positivas

- As conexões funcionam com confiabilidade na máquina de desenvolvimento, sem
  ajustes de ambiente.
- O projeto entra em uso na versão ativamente desenvolvida da biblioteca.
- O `psycopg` v3 oferece uma interface assíncrona nativa, o que pode ser útil se
  a API mais tarde passar a usar acesso assíncrono ao banco.

### Negativas

- As URLs de conexão precisam usar o prefixo `postgresql+psycopg://`. O esquema
  simples `postgresql://` resolve para psycopg2 no SQLAlchemy, então omitir o
  sufixo gera um erro confuso de "driver not installed". Isso é fácil de esquecer
  e vale checar primeiro sempre que surgir um problema de conexão.
- A maioria dos tutoriais, respostas do StackOverflow e exemplos de código
  existentes assume a v2, então os exemplos encontrados online podem precisar de
  adaptação.

### Revisitar quando

Não se antecipa uma revisão. Se o projeto mais tarde evoluir para um fluxo de
desenvolvimento totalmente containerizado, a restrição original de codificação
já não se aplicaria — mas ainda assim não haveria motivo para voltar à v2.

## Relacionado

Um problema separado de ambiente foi diagnosticado junto com este: uma instância
nativa do PostgreSQL na máquina de desenvolvimento ocupava a porta 5432, então
as conexões destinadas ao container acabavam atingindo o servidor errado. Por
isso, o banco do projeto fica exposto na porta `5433` no host. Isso está
documentado no README em vez de ser tratado como registro de decisão, porque é
uma acomodação local do ambiente, e não uma escolha arquitetural.

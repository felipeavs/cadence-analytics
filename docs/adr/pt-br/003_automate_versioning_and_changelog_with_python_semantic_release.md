# ADR 003: Automatizar versionamento e changelog com python-semantic-release

**Status:** Aceito
**Date:** 2026-08-07

## Contexto

O projeto precisa de uma forma de acompanhar qual versão do código está em
execução e manter um histórico legível do que mudou entre versões. Fazer isso à
mão — aumentar um número de versão, escrever uma entrada no changelog,
criar uma tag, publicar um release — envolve quatro passos manuais fáceis de
esquecer ou executar de forma inconsistente, principalmente em um projeto solo
onde nada obriga essa disciplina.

Como as mensagens de commit já iriam seguir Conventional Commits, as informações
necessárias para derivar os quatro passos já existem no histórico de commits:
`feat:` implica um bump menor, `fix:` um patch, e os assuntos dos commits são
as entradas do changelog.

## Decisão

Usar `python-semantic-release` para derivar números de versão, atualizar o
changelog, criar tags e publicar releases no GitHub automaticamente, acionados
por pushes para `main`.

O versionamento acontece apenas em `main`. A branch `develop` acumula trabalho
sem gerar versões; um release é criado quando `develop` é mergeado em `main`.

## Justificativa

A alternativa — versionar tanto em `main` quanto em `develop` — foi considerada
e rejeitada. As duas branches computariam uma versão a partir dos mesmos
commits, o que ou gera tags duplicadas ou faz com que os números de versão
se desajustem entre as branches. As duas também escreveriam no mesmo
`CHANGELOG.md`, gerando conflito de merge a cada promoção de `develop` para
`main`. O modelo de uma única branch de release é o pressuposto do design da
ferramenta, e trabalhar contra isso cria problemas que ela foi feita para evitar.

Versões de pré-lançamento em `develop` (`0.2.0-rc.1`) teriam sido a forma
suportada de obter versionamento em ambas as branches, porém, para um projeto
solo, as tags extras geram ruído sem um consumidor que se beneficie delas.

## Consequências

### Positivas

- Números de versão, changelog e releases ficam sempre consistentes com o
  histórico de commits, sem um passo manual para esquecer.
- A disciplina nas mensagens de commit passa a ter um retorno visível, o que a
  reforça.
- O histórico de releases vira documentação do projeto.

### Negativas

- Commits que não seguem Conventional Commits são ignorados silenciosamente na
  hora de calcular a versão. Uma alteração enviada como `"fixes"` em vez de
  `"fix:"` não aparecerá no changelog nem acionará um release.
- Apenas `feat`, `fix` e `perf` geram bump de versão. Um release composto
  exclusivamente por commits `chore`, `docs` ou `ci` não gera nova versão — o
  que é o comportamento correto, mas pode parecer uma falha se for inesperado.

## Notas de configuração

Três detalhes de configuração causaram falhas silenciosas na configuração e
foram registrados aqui porque nenhum deles gera uma mensagem de erro evidente:

**O comando é `semantic-release version`, não `publish`.** Na v8 os comandos
foram reorganizados; `publish` ainda existe, mas faz upload de artefatos para um
release existente em vez de criar um. Usá-lo não gera release e nem erro.

**O `CHANGELOG.md` precisa conter o marcador de inserção.** O changelog está
configurado com `mode = "update"`, o que insere novas entradas em um marcador
em vez de reescrever o arquivo. Sem a presença de `<!-- version list -->` no
arquivo, a ferramenta não tem onde escrever e pula a etapa do changelog em
silêncio. O marcador não deve ser removido ao editar o changelog manualmente.

**O `__version__.py` precisa conter uma atribuição em Python.** A configuração
`version_variables` procura o padrão `__version__ = "..."`. Um arquivo contendo
apenas um número de versão sem atribuição não é reconhecido e fica sem alteração
— novamente, sem erro.

O guard de loop depende de `commit_message` contendo `[skip ci]`: o próprio
commit de release é um push para `main`, o que de outra forma reativaria o fluxo
indefinidamente. Se o template de mensagem do commit for alterado, o guard deve
ser preservado.

### Revisitar quando

Se o projeto algum dia ganhar um segundo colaborador ou um alvo real de deploy,
versões de pré-lançamento em `develop` passam a valer a pena reconsiderar — a
partir desse momento existe um consumidor real que se beneficia de poder
referenciar uma build específica em desenvolvimento.

# ADR 001: Usar Alembic com migrações em SQL puro em vez de um ORM

**Status:** Aceito
**Date:** 2026-08-07

## Contexto

Espera-se que o schema do banco de dados deste projeto mude repetidamente à
medida que o pipeline evoluir — novas métricas aparecerão assim que o gerador
sintético de dados e a ingestão do Garmin estiverem funcionando, o suporte para
múltiplos usuários introduzirá campos de autenticação, e o modelo analítico
pode precisar ser reorganizado conforme os padrões de consulta fiquem mais
claros.

Aplicar alterações de schema manualmente não é viável: não haveria histórico de
como o schema evoluiu, não seria possível recriar o banco de dados do zero com
confiabilidade, e também não seria possível reverter uma mudança. Portanto, as
migrações de schema precisam ser versionadas junto com o código da aplicação.

No ecossistema Python, a resposta convencional é o Alembic, e o Alembic é
mais comumente combinado com o ORM SQLAlchemy — o que permite migrações
geradas automaticamente comparando classes de modelo Python com o banco de
dados em execução. Essa combinação é quase um padrão em projetos FastAPI
modernos.

## Decisão

Usar o Alembic para versionamento de schema, mas escrever as migrações como SQL
puro via `op.execute(...)` em vez de adotar o ORM SQLAlchemy neste estágio.

## Justificativa

O principal benefício buscado é *alterações de schema versionadas, reversíveis e
reproduzíveis*. O Alembic já entrega isso por si só; o ORM é uma preocupação
separada que costuma ser agrupada a ele.

Dada a familiaridade existente com PostgreSQL — incluindo funções, triggers e
otimização de consultas — escrever o DDL diretamente é mais rápido e claro do
que expressá-lo por meio de uma camada de abstração, além de manter controle
completo sobre recursos que ORMs costumam lidar de maneira incômoda (índices
parciais, triggers, funções personalizadas).

Adotar o ORM agora adicionaria uma segunda curva de aprendizado sobre o próprio
Alembic, em um momento em que a prioridade do projeto é fazer os dados fluírem
de ponta a ponta.

### Alternativas consideradas

- **Alembic + ORM SQLAlchemy** — o padrão do ecossistema e que permite
  `--autogenerate`. Rejeitado por enquanto para evitar introduzir duas novas
  abstrações ao mesmo tempo, e porque o controle em nível SQL importa mais
  neste estágio do que a conveniência da autogeração.
- **Scripts SQL simples no diretório de inicialização do Postgres** — fáceis de
  configurar, mas só rodam na primeira inicialização do volume. Aplicar uma
  mudança depois exigiria destruir e recriar o banco de dados, e não haveria
  histórico nem caminho de rollback.

## Consequências

### Positivas

- Controle total sobre o DDL gerado, incluindo recursos específicos do PostgreSQL.
- Superfície conceitual menor: uma nova ferramenta (Alembic) em vez de duas.
- As migrações são lidas como SQL, o que é diretamente revisável e portátil.

### Negativas

- Sem `--autogenerate`: cada migração é escrita à mão, o que é mais lento e
  deixa mais espaço para erro humano.
- O schema atual não está representado em Python, então o código da aplicação
  não possui um modelo tipado das tabelas que consulta.
- Diverge do layout mais comum de projetos FastAPI, o que pode ser ligeiramente
  surpreendente para outros desenvolvedores.

### Revisitar quando

Essa decisão deve ser reconsiderada se as migrações escritas manualmente
passarem a parecer propensas a erro, ou se modelos tipados melhorariam
significativamente a camada de API.

Migrar para SQLAlchemy mais tarde deve ser simples: as migrações existentes
continuam válidas independentemente de como foram escritas, e o ORM pode ser
introduzido declarando classes de modelo que descrevam o schema já existente —
um conjunto correto de classes deveria produzir uma migração autogerada vazia,
o que serve como verificação de que as duas representações concordam.

A maior parte dessa migração seria a camada de consultas, não o schema. Por isso,
manter todo o SQL confinado em `api/repositories/` é uma restrição deliberada
desta decisão, para que qualquer transição futura fique contida em um único
módulo.

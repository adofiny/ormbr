# SPEC — ORMBr Framework for Delphi

> Documento gerado por engenharia reversa do código-fonte (`Source/`, `Components/`, `Projects/`, `Examples/`).
> Itens marcados com **[INFERIDO]** foram deduzidos do comportamento do código e não estão explícitos em comentários ou documentação.

---

## SEÇÃO 1 — Identificação do Projeto

| Campo | Valor |
|---|---|
| Nome do Sistema | ORMBr — ORM Brasil Framework for Delphi |
| Módulo / Subsistema | Projeto completo: Core (ORM/DML), ObjectSet, DataSet, Criteria, Middleware, RESTful (Client/Server), LiveBindings, Metadata, Monitor, Componentes de IDE e ferramentas auxiliares |
| Versão do produto analisada | 1.1.8 (`boss.json`) |
| Versão da SPEC | 1.0 |
| Data de Criação | 24/11/2026 |
| Autor | Gerado automaticamente (delphi-spec) a partir do código-fonte |
| Autor original do framework | Isaque Pinheiro (cabeçalhos das units, criado em 20/07/2016) |
| Licença | GNU LGPL v3 |
| Revisado por | — |
| Status | Rascunho |

---

## SEÇÃO 2 — Objetivo e Escopo

### 2.1 Objetivo
O ORMBr é um framework de Mapeamento Objeto-Relacional (ORM) para Delphi. Ele permite que aplicações modelem o domínio como classes anotadas com atributos e persistam esses objetos em bancos relacionais (e MongoDB) sem escrever SQL manualmente. O framework gera os comandos DML no dialeto do banco, faz o bind objeto↔registro, gerencia relacionamentos (1:1, 1:N) com ações em cascata e expõe os dados de três formas: como listas de objetos (ObjectSet), como DataSets em memória ligados à UI (FDMemTable/ClientDataSet) e como recursos REST.

### 2.2 Escopo (o que está incluído)
- Mapeamento de classes para tabelas via atributos (`[Entity]`, `[Table]`, `[Column]`, `[PrimaryKey]`, `[Association]` etc., definidos na dependência DBCBr).
- Geração de SQL (SELECT/INSERT/UPDATE/DELETE, paginação, sequências) para 14 dialetos: Firebird, Firebird 3, InterBase, MySQL, PostgreSQL, SQLite, MS SQL Server, Oracle, NexusDB, ElevateDB, AbsoluteDB, Advantage (ADS), MongoDB e NoSQL genérico.
- API **ObjectSet** (`TManagerObjectSet`, `IContainerObjectSet<M>`): CRUD sobre listas de objetos, com transação automática e cascata.
- API **DataSet** (`TManagerDataSet`, `IContainerDataSet<M>`): CRUD via FDMemTable ou ClientDataSet, master-detail multinível, lookup, campos calculados e agregados, `ApplyUpdates`.
- Paginação incremental (`NextPacket`) e carga sob demanda (`LoadLazy`, `Lazy<T>`).
- Tipos de apoio: `Nullable<T>`, `TBlob` (com compressão e Base64), `Lazy<T>`.
- Construtor fluente de SQL (`ICriteria`) e consultas tipadas (`TCriteria<M>`).
- Middlewares de eventos (Before/After Insert/Update/Delete) e de Query Scope (WHERE/ORDER BY globais por entidade).
- Serialização JSON de objetos e listas (`TORMBrJson`).
- Camada RESTful: servidores para Horse, DataSnap, DelphiMVC, MARS e WiRL; clientes para os mesmos e WebService genérico; documentação Swagger para Horse.
- Middleware Horse (`Horse.ORMBr`) para body tipado `application/jsonbr`.
- LiveBindings VCL/FMX via atributo `[LiveBindingsControl]`.
- Comparação modelo↔banco e geração de DDL (`TModelDbCompare`).
- Monitor visual dos comandos SQL executados (`TCommandMonitor`).
- Componentes de IDE (pacotes design-time) e ferramentas: Gerador de Modelos, Instalador, Baixador de Dependências.

### 2.3 Fora do Escopo (o que NÃO está incluído)
- Conexão física com o banco: delegada à dependência **DBEBr** (`IDBConnection`, `TFactoryFireDAC` etc.).
- Definição dos atributos de mapeamento e do explorador de metadados: dependência **DBCBr**.
- Construção de SQL de baixo nível: dependência **CQLBr**.
- Motor JSON: dependência **JSONBr**.
- Autenticação/autorização no lado servidor REST (o servidor não implementa controle de acesso por usuário; apenas o bloqueio por `[NotServerUse]`).
- Suíte de testes automatizados (nenhum teste DUnit/DUnitX encontrado no repositório).
- Migrations versionadas (há apenas comparação de modelo e geração de DDL).

---

## SEÇÃO 3 — Atores e Perfis de Usuário

| ID | Ator | Descrição | Permissões |
|---|---|---|---|
| AT-001 | Desenvolvedor Delphi | Consumidor principal do framework. Cria as classes de modelo, configura conexão e usa os managers/containers. | Acesso total à API pública. |
| AT-002 | Aplicação cliente (runtime) | Executável que usa o ORMBr para ler e gravar dados. | Executa CRUD conforme o mapeamento e as restrições (`NoInsert`, `NoUpdate` etc.). |
| AT-003 | Consumidor REST | Cliente HTTP (outro sistema ou cliente ORMBr REST) que chama os recursos expostos pelo servidor. | GET/POST/PUT/DELETE em `api/ormbr/:resource`; bloqueado em leitura para entidades com `[NotServerUse]`. |
| AT-004 | Banco de dados | SGBD relacional ou MongoDB que recebe os comandos gerados. | — (sistema externo) |
| AT-005 | Instalador / Administrador de ambiente | Instala os pacotes na IDE e baixa as dependências. | Usa ORMBr Install, ORMBr Dependencies e `boss install`. |
| AT-006 | Usuário do Gerador de Modelos | Desenvolvedor que gera classes de modelo a partir de um banco existente. | Conecta em bancos via FireDAC e grava units `.pas`. |

---

## SEÇÃO 4 — Requisitos Funcionais

### 4.1 Mapeamento e geração de SQL (Core)

| ID | Descrição | Prioridade | Ator | Observações |
|---|---|---|---|---|
| RF-001 | Mapear classes para tabelas por atributos (`[Entity]`, `[Table]`, `[Column]`, `[PrimaryKey]`, `[Sequence]`, `[OrderBy]`, `[Indexe]`, `[ForeignKey]`, `[JoinColumn]`, `[Association]`, `[CascadeActions]`, `[Restrictions]`, `[Dictionary]`, `[Enumeration]`, `[NotServerUse]`). | Alta | AT-001 | Atributos vêm do DBCBr; registro com `TRegisterClass.RegisterEntity`. |
| RF-002 | Gerar SELECT com todas as colunas mapeadas, excluindo `VirtualData` e `JoinColumn`, e montar JOINs (Inner/Left/Right/Full) a partir de `[JoinColumn]`. | Alta | AT-002 | `TDMLGeneratorAbstract.GetCriteriaSelect`. |
| RF-003 | Gerar INSERT somente com colunas não nulas e sem restrição `NoInsert`. | Alta | AT-002 | `GeneratorInsert`, `TCommandInserter`. |
| RF-004 | Gerar UPDATE somente com os campos efetivamente alterados (dirty tracking). | Alta | AT-002 | `ModifyFieldsCompare` + `TCommandUpdater`. |
| RF-005 | Gerar DELETE filtrando pelas colunas da chave primária. | Alta | AT-002 | `TCommandDeleter`. |
| RF-006 | Gerar valor da PK automaticamente conforme `TGeneratorType`: sequência/generator do banco (`SequenceInc`) ou GUID de 32, 36 ou 38 caracteres. | Alta | AT-002 | `TCommandInserter.GenerateInsert`. |
| RF-007 | Paginar consultas com a sintaxe nativa de cada dialeto (`FIRST/SKIP`, `TOP`, `LIMIT/OFFSET`, `ROWNUM` etc.). | Alta | AT-002 | `GeneratorPageNext` e overrides. |
| RF-008 | Manter cache por classe dos comandos SELECT e INSERT gerados. | Média | AT-002 | `TQueryCache`. |
| RF-009 | Registrar geradores de dialeto por driver e localizar o gerador pelo `TDriverName` da conexão. | Alta | AT-001 | `TDriverRegister`; o registro acontece no `initialization` da unit do dialeto. |
| RF-010 | Enviar cada comando e seus parâmetros ao monitor de SQL e/ou a um callback de monitoramento, quando configurados. | Baixa | AT-001 | `_SendCommandMonitor`. |
| RF-011 | Preencher automaticamente associações não-lazy (1:1, N:1, 1:N, N:N) ao carregar um objeto, de forma recursiva. | Alta | AT-002 | `FillAssociation`; ignorado no MongoDB. |
| RF-012 | Carregar associações marcadas como lazy somente quando solicitado (`LoadLazy`). | Média | AT-001 | `FillAssociationLazy`. |

### 4.2 API ObjectSet

| ID | Descrição | Prioridade | Ator | Observações |
|---|---|---|---|---|
| RF-013 | Registrar repositórios por classe com tamanho de página opcional (`AddRepository<T>(APageSize)`). | Alta | AT-001 | `AddAdapter<T>` está obsoleto. |
| RF-014 | Buscar todos (`Find<T>`), por ID inteiro/string (`Find<T>(AID)`) e por filtro (`FindWhere<T>(Where, OrderBy)`). | Alta | AT-001 | |
| RF-015 | Inserir, atualizar e excluir objetos com execução de middlewares Before/After. | Alta | AT-001 | `TManagerObjectSet.Insert/Update/Delete`. |
| RF-016 | Registrar o estado original de um objeto antes da edição (`Modify`) para calcular os campos alterados. | Alta | AT-001 | `_AddObjectState`, inclusive filhos e listas. |
| RF-017 | Executar cascata de INSERT, UPDATE e DELETE nos objetos associados conforme `[CascadeActions]`. | Alta | AT-002 | `CascadeActionsExecute`. |
| RF-018 | Propagar a PK gerada do mestre para as FKs dos filhos (`CascadeAutoInc`). | Alta | AT-002 | `SetAutoIncValueChilds`. |
| RF-019 | No UPDATE mestre-detalhe, inserir filhos novos e excluir filhos removidos da lista. | Alta | AT-002 | Filhos que estavam em `FObjectState` e não foram atualizados são excluídos. |
| RF-020 | Paginar listas (`NextPacket`), com filtro e ordenação mantidos entre páginas. | Média | AT-001 | |
| RF-021 | Operar em modo "lista aninhada" (`OwnerNestedList = True`) com navegação `First/Next/Prior/Last/Eof/Bof`, `Current` e `New`. | Média | AT-001 | |
| RF-022 | Expor o dicionário de campos alterados (`ModifiedFields`) e indicar se a entidade usa sequência (`ExistSequence`). | Baixa | AT-001 | |

### 4.3 API DataSet

| ID | Descrição | Prioridade | Ator | Observações |
|---|---|---|---|---|
| RF-023 | Ligar uma classe a um `TFDMemTable` ou `TClientDataSet`, criando os campos a partir do mapeamento. | Alta | AT-001 | `TContainerFDMemTable<M>`, `TContainerClientDataSet<M>`. |
| RF-024 | Abrir dados (`Open`, `Open(AID)`, `OpenWhere`), fechar, navegar e editar (`Insert/Append/Edit/Post/Delete/Cancel`). | Alta | AT-001 | |
| RF-025 | Persistir as alterações pendentes no banco com `ApplyUpdates(MaxErros)`, em ordem INSERT → UPDATE → DELETE e incluindo os detalhes. | Alta | AT-001 | Dispara `BeforeApplyUpdates`/`AfterApplyUpdates`. |
| RF-026 | Montar master-detail multinível (`AddAdapter<TDetail, TMaster>`) e reabrir os detalhes a cada scroll do mestre. | Alta | AT-001 | `OpenDataSetChilds`. |
| RF-027 | Criar campos de lookup entre adapters (`AddLookupField<T, M>`). | Média | AT-001 | |
| RF-028 | Criar campos calculados e agregados a partir do mapeamento (`[AggregateField]`). | Média | AT-001 | `ormbr.dataset.fields`. |
| RF-029 | Preservar os eventos que o desenvolvedor configurou no DataSet e encadeá-los aos eventos internos do ORM. | Alta | AT-001 | `GetDataSetEvents`/`SetDataSetEvents`. |
| RF-030 | Recarregar o registro atual ou um registro filtrado (`RefreshRecord`, `RefreshRecordWhere`). | Média | AT-001 | |
| RF-031 | Buscar a próxima página automaticamente ao chegar ao fim do DataSet (`AutoNextPacket`). | Média | AT-001 | |
| RF-032 | Gravar um objeto diretamente no registro atual do DataSet (`Save(AObject)`) e obter o registro atual como objeto (`Current`). | Média | AT-001 | |
| RF-033 | Atualizar a associação 1:1 quando o campo FK do registro mudar. | Média | AT-002 | `RefreshDataSetOneToOneChilds`. |

### 4.4 Criteria, Middleware, JSON e tipos

| ID | Descrição | Prioridade | Ator | Observações |
|---|---|---|---|---|
| RF-034 | Construir SQL de forma fluente (SELECT/INSERT/UPDATE/DELETE, JOINs, WHERE, GROUP BY, HAVING, ORDER BY, CASE, FIRST/SKIP). | Média | AT-001 | `ICriteria`. |
| RF-035 | Executar SQL livre e retornar `IDBResultSet`, lista tipada ou objeto único (`TCriteria<M>.AsList/AsValue`). | Média | AT-001 | |
| RF-036 | Registrar eventos Before/After Insert/Update/Delete por entidade (nome da classe). | Média | AT-001 | `BeforeInsertMiddleware.AddEvent(...)` etc. |
| RF-037 | Registrar escopos de consulta (WHERE e ORDER BY) por entidade, aplicados em toda consulta gerada. | Média | AT-001 | `QueryScopeMiddleware.AddWhere/AddOrderBy`. |
| RF-038 | Serializar e desserializar objetos e listas em JSON, com formato de data configurável (inclusive ISO 8601). | Alta | AT-001 / AT-003 | `TORMBrJson`. |
| RF-039 | Representar valores anuláveis (`Nullable<T>` e aliases `NullString`, `NullInteger`, `NullDate` etc.). | Alta | AT-001 | |
| RF-040 | Manipular BLOBs: ler de campo/arquivo, salvar em arquivo, comprimir, converter para Base64, bytes, `TPicture`/`TBitmap` (VCL). | Média | AT-001 | `TBlob`. |

### 4.5 RESTful

| ID | Descrição | Prioridade | Ator | Observações |
|---|---|---|---|---|
| RF-041 | Expor automaticamente as entidades registradas como recursos REST, com GET/POST/PUT/DELETE em `api/ormbr/:resource` (rota configurável). | Alta | AT-003 | Horse, DataSnap, DMVC, MARS e WiRL. |
| RF-042 | Interpretar parâmetros de consulta no estilo OData: `$filter`, `$orderby`, `$top`, `$skip`, `$count`, `$select`, `$expand`, `$search`, e ID no caminho `recurso(id)`. | Alta | AT-003 | `TRESTQueryParse`. `$select`, `$expand` e `$search` são lidos, mas não foi identificado uso no `ParseFind`. [INFERIDO] |
| RF-043 | Devolver a contagem de registros no header `ResultCount` quando `$count=true`. | Baixa | AT-003 | Servidor Horse. |
| RF-044 | Retornar a PK gerada na resposta do POST. | Média | AT-003 | `cRESOURCEINSERT`. |
| RF-045 | Usar o mesmo `TManagerObjectSet`/`TManagerDataSet` contra um servidor REST trocando a conexão (`DRIVERRESTFUL`). | Alta | AT-001 | `IRESTConnection`. |
| RF-046 | Configurar autenticação no cliente REST (nenhuma, Basic, Bearer, OAuth1, OAuth2), proxy e eventos `OnAuthentication`, `OnBeforeCommand`, `OnAfterCommand`, `OnErrorCommand`. | Média | AT-001 | `TORMBrClientBase`. Só o lado cliente; o servidor não valida credenciais. [INFERIDO] |
| RF-047 | Publicar documentação Swagger dos recursos no servidor Horse. | Baixa | AT-003 | `ormbr.server.swagger.horse` (GBSwagger). |
| RF-048 | Converter body `application/jsonbr` em objeto/lista tipada no Horse (`Req.Body<T>`) e serializar `Res.Content`. | Média | AT-001 | `Horse.ORMBr`. |

### 4.6 Metadata, UI e ferramentas

| ID | Descrição | Prioridade | Ator | Observações |
|---|---|---|---|---|
| RF-049 | Comparar o modelo de classes com o banco de destino e executar os comandos DDL resultantes. | Média | AT-001 | `TModelDbCompare`. |
| RF-050 | Ligar propriedades de objetos a controles VCL/FMX por `[LiveBindingsControl]`. | Baixa | AT-001 | |
| RF-051 | Exibir em tela os comandos SQL e parâmetros executados (singleton). | Baixa | AT-001 | `TCommandMonitor.GetInstance`. |
| RF-052 | Gerar units de modelo a partir das tabelas de um banco (MSSQL, Firebird, MySQL, SQLite, PostgreSQL, Oracle, DB2, InterBase), com opções de nomes em minúsculas e lazy. | Média | AT-006 | Projeto "Gerador Modelo". |
| RF-053 | Instalar os pacotes na IDE por assistente (escolha de versão do Delphi, Win32/Win64, FDMemTable ou ClientDataSet, pacotes REST). | Média | AT-005 | Projeto "ORMBr Install". |
| RF-054 | Baixar e extrair as dependências (CQLBr, DBCBr, DBEBr, JSONBr) do GitHub por tag ou branch. | Média | AT-005 | Projeto "ORMBr Dependencies". |
| RF-055 | Disponibilizar componentes não-visuais na paleta (Manager FDMemTable, Manager ClientDataSet, Manager ObjectSet, Driver Links por banco). | Média | AT-001 | Pacotes `dcl*.dpk`. |

---

## SEÇÃO 5 — Requisitos Não Funcionais

| ID | Categoria | Descrição | Critério de Aceitação |
|---|---|---|---|
| RNF-001 | Compatibilidade | Compilar do Delphi XE (VER220) até o Delphi 13 (VER370), e nas versões seguintes sem editar `ormbr.inc` (cascata de `CompilerVersion`). | `Projects/CompileCheck` compila sem erros em cada versão suportada. |
| RNF-002 | Compatibilidade | Suportar 14 dialetos de banco por meio de geradores plugáveis. | Cada dialeto registrado gera SQL válido para CRUD e paginação. |
| RNF-003 | Portabilidade | Componentes de driver declarados para Win32, Win64, WinArm64, macOS (32/64/ARM64) e Linux (32/64/ARM64). | `ComponentPlatformsAttribute` em `ormbr.driver.link.*`. |
| RNF-004 | Portabilidade | Suportar UI VCL e FMX por diretivas de compilação (`VCL`/`FMX` em `ormbr.inc`). [INFERIDO] | Exemplos VCL e FMX compilam e executam. |
| RNF-005 | Configurabilidade | Escolher o DataSet em memória (`USEFDMEMTABLE` ou `USECLIENTDATASET`) e o modo REST (`DRIVERRESTFUL`) por diretiva. | Sem a diretiva, `TManagerDataSet` levanta erro explícito. |
| RNF-006 | Performance | Reaproveitar SQL gerado por classe (cache de SELECT/INSERT) e enviar no UPDATE só os campos alterados. | Segunda consulta à mesma classe não percorre o RTTI de colunas de novo. [INFERIDO] |
| RNF-007 | Performance | Paginação no servidor de banco via `APageSize` e carga lazy de associações. | Consultas com `APageSize > -1` usam a sintaxe de paginação do dialeto. |
| RNF-008 | Integridade | Toda operação de escrita roda em transação; se o chamador já abriu uma transação, o ORM não faz commit nem rollback. | Rollback automático em exceção quando a transação é do ORM. |
| RNF-009 | Gestão de recursos | Conectar sob demanda e desconectar ao final quando a conexão estava fechada antes da operação. | Estado da conexão restaurado após cada operação. |
| RNF-010 | Segurança | Comandos DML gerados usam parâmetros (`:coluna`) para valores de INSERT/UPDATE/DELETE. | Nenhum valor de usuário concatenado nesses comandos. |
| RNF-011 | Segurança | Cláusulas `Where`/`$filter` e valores de associação/ID são concatenados como texto no SQL. | Ver riscos R-01 e R-02 na Seção 12.3. |
| RNF-012 | Manutenibilidade | Arquitetura em camadas (Manager → Adapter → Session → CommandExecutor → CommandFactory → DMLGenerator) com interfaces e genéricos. | Novo dialeto exige apenas uma unit de gerador e o registro em `TDriverRegister`. |
| RNF-013 | Distribuição | Instalação via Boss (`boss install`) com dependências versionadas (`^1.1.x`). | `boss.json` resolve DBCBr, DBEBr, CQLBr e JSONBr. |
| RNF-014 | Encoding | Units-fonte em Windows-1252 (ANSI). [INFERIDO] | Ferramentas de edição devem preservar o encoding para não corromper acentos. |
| RNF-015 | Limite operacional | O adapter de FDMemTable fixa `FetchOptions.RecsMax = 300000`. | Conjuntos maiores são truncados silenciosamente. [INFERIDO] |
| RNF-016 | Testabilidade | Não há testes automatizados no repositório. | — (lacuna; ver Seção 13) |

---

## SEÇÃO 6 — Casos de Uso

### UC-001: Mapear uma entidade

| Campo | Valor |
|---|---|
| ID | UC-001 |
| Nome | Mapear uma entidade |
| Ator Principal | AT-001 Desenvolvedor |
| Pré-condições | DBCBr instalado; tabela existente ou planejada. |
| Pós-condições | Classe registrada e reconhecida pelo `TMappingExplorer`. |
| Trigger | Necessidade de persistir um novo tipo de objeto. |

**Fluxo Principal:**
1. O desenvolvedor cria a classe com `[Entity]`, `[Table]` e `[PrimaryKey]`.
2. Anota as propriedades com `[Column]` e, se preciso, `[Restrictions]`, `[Dictionary]` e `[JoinColumn]`.
3. Declara as associações com `[Association]` e `[CascadeActions]`.
4. Registra a classe com `TRegisterClass.RegisterEntity` no `initialization`.

**Fluxo Alternativo:**
- 1a. Gerar a classe pelo Gerador de Modelos (UC-008).

**Fluxo de Exceção:**
- 2b. Sem `[Column]`: o INSERT falha com "Nenhum atributo [Column()] foi definido nas propriedades da classe".
- 1b. Sem `[PrimaryKey]`: UPDATE/DELETE/cascata falham com "PrimaryKey not found on your model!".

---

### UC-002: CRUD de objetos com ObjectSet

| Campo | Valor |
|---|---|
| ID | UC-002 |
| Nome | Persistir objetos via ObjectSet |
| Ator Principal | AT-002 Aplicação |
| Pré-condições | Conexão `IDBConnection` criada; unit do gerador de dialeto na cláusula `uses`. |
| Pós-condições | Registro gravado e PK preenchida no objeto. |
| Trigger | Chamada a `Insert<T>`, `Update<T>` ou `Delete<T>`. |

**Fluxo Principal:**
1. A aplicação cria `TManagerObjectSet.Create(Conn)` e chama `AddRepository<T>`.
2. Para inclusão, cria o objeto (`New<T>`), preenche e chama `Insert<T>(Obj)`.
3. O manager executa o middleware `BeforeInsert`.
4. O adapter abre a transação (se não houver uma externa), gera a PK, executa o INSERT e propaga a PK para os filhos.
5. Executa a cascata de INSERT nos associados.
6. Faz commit e executa o middleware `AfterInsert`.

**Fluxo Alternativo:**
- 2a. Alteração: busca com `Find<T>(ID)`, chama `Modify<T>(Obj)` para guardar o estado, altera e chama `Update<T>(Obj)`. Só os campos alterados são enviados; filhos removidos da lista são excluídos.
- 2b. Exclusão: `Delete<T>(Obj)` exclui os filhos em cascata antes do mestre.

**Fluxo de Exceção:**
- 4a. Erro de banco: rollback (se a transação é do ORM) e nova exceção com a mensagem original.
- 1a. Classe não registrada: "Use the AddAdapter<T> method to add the class to manager".

---

### UC-003: Cadastro master-detail com DataSet

| Campo | Valor |
|---|---|
| ID | UC-003 |
| Nome | Editar dados master-detail em grid |
| Ator Principal | AT-002 Aplicação (operada pelo usuário final do sistema que usa o ORMBr) |
| Pré-condições | `USEFDMEMTABLE` ou `USECLIENTDATASET` definido; DataSets na tela. |
| Pós-condições | Alterações gravadas no banco. |
| Trigger | Abertura do formulário. |

**Fluxo Principal:**
1. A aplicação cria `TManagerDataSet` e registra `AddAdapter<TMaster>(DS, PageSize)`, `AddAdapter<TDetail, TMaster>(DSDetail)` e lookups.
2. Chama `Open<TMaster>`; o ORM cria os campos e carrega a primeira página.
3. A cada scroll do mestre, os detalhes são reabertos com o SQL de associação.
4. O usuário edita; no `BeforePost` o ORM valida os campos `NotNull`.
5. A aplicação chama `ApplyUpdates<TMaster>(0)`; o ORM grava INSERTs, UPDATEs e DELETEs do mestre e dos detalhes em transação.

**Fluxo Alternativo:**
- 3a. Com `AutoNextPacket`, a próxima página é carregada ao chegar ao fim.
- 5a. `CancelUpdates` descarta as alterações pendentes.

**Fluxo de Exceção:**
- 4a. Campo obrigatório nulo: `EFieldValidate` com a mensagem do `[Dictionary]`.
- 2a. Campo com `[FieldEvents]` sem o evento atribuído: "%s event required in column [%s]!".
- 1a. Tipo de DataSet incompatível: "Is not TFDMemTable type" / "Is not TClientDataSet type".

---

### UC-004: Consultar com filtro, paginação e escopo

| Campo | Valor |
|---|---|
| ID | UC-004 |
| Nome | Consultar dados filtrados e paginados |
| Ator Principal | AT-001 / AT-002 |
| Pré-condições | Repositório registrado com `APageSize > -1` para paginar. |
| Pós-condições | Lista de objetos (ou DataSet) com a página pedida. |
| Trigger | `FindWhere`, `OpenWhere` ou `NextPacket`. |

**Fluxo Principal:**
1. Opcionalmente, o desenvolvedor registra escopos com `QueryScopeMiddleware.AddWhere/AddOrderBy`.
2. A aplicação chama `FindWhere<T>('campo = x', 'campo')`.
3. O gerador compõe SELECT + WHERE de escopo + WHERE informado + ORDER BY de escopo/informado + paginação.
4. O resultado é convertido em objetos e as associações não-lazy são preenchidas.
5. `NextPacket` busca as páginas seguintes mantendo o filtro; quando vem vazia, `FetchingRecords` passa a `True` e não há novas buscas.

**Fluxo de Exceção:**
- 3a. Driver não registrado: "O driver X não está registrado, adicione a unit ormbr.dml.generator.???.pas".

---

### UC-005: Expor entidades como API REST (Horse)

| Campo | Valor |
|---|---|
| ID | UC-005 |
| Nome | Publicar API REST das entidades |
| Ator Principal | AT-001 (configura) / AT-003 (consome) |
| Pré-condições | Entidades registradas; conexão de banco no servidor. |
| Pós-condições | Rotas GET/POST/PUT/DELETE disponíveis. |
| Trigger | Inicialização do servidor. |

**Fluxo Principal:**
1. O desenvolvedor cria `TRESTServerHorse.Create(Self, Conn, 'api/ormbr')`.
2. O consumidor chama `GET api/ormbr/cliente?$filter=id eq 1&$orderby=nome&$top=10&$skip=0`.
3. O servidor resolve o recurso pelo nome, verifica `[NotServerUse]`, traduz os operadores e consulta.
4. A resposta é a lista ou o objeto em JSON (`application/json`); com `$count=true`, o header `ResultCount` é preenchido.
5. POST insere (resposta com a PK), PUT atualiza pela PK do body e DELETE exclui por ID ou `$filter`.

**Fluxo de Exceção:**
- 3a. Recurso inexistente: `{"exception":"Resource [X] not registered on the server!"}`.
- 3b. `[NotServerUse]`: `{"exception":"Resource [X] without access permission..."}`.
- 5a. DELETE sem ID nem filtro: `{"exception":"The delete method needs the ID parameter!"}`.
- 5b. DELETE sem registro: `{"result":"No records found to delete, with the filter entered!"}`.
- Em todos os casos, o Horse devolve a mensagem no corpo com status HTTP padrão (200). [INFERIDO]

---

### UC-006: Consumir API REST com o cliente ORMBr

| Campo | Valor |
|---|---|
| ID | UC-006 |
| Nome | Usar manager ORMBr sobre servidor REST |
| Ator Principal | AT-001 |
| Pré-condições | `DRIVERRESTFUL` definido; componente cliente (Horse/DataSnap/DMVC/MARS/WiRL/WS) configurado. |
| Pós-condições | CRUD remoto transparente. |
| Trigger | Mesmas chamadas do UC-002/UC-003. |

**Fluxo Principal:**
1. O desenvolvedor configura `Host`, `Port`, `Protocol`, `APIContext` e `Authenticator`.
2. Passa `Client.AsConnection` (ou `IRESTConnection`) ao manager.
3. As chamadas de CRUD viram requisições HTTP, e o JSON retornado é convertido em objetos.

**Fluxo de Exceção:**
- 3a. Falha HTTP: `EORMBrRESTException` com URL, recurso, método, mensagem e código; o evento `OnErrorCommand` é disparado.
- 3b. POST sem dados: "Não foi passado o parâmetro com os dados do insert!".

---

### UC-007: Sincronizar modelo com o banco

| Campo | Valor |
|---|---|
| ID | UC-007 |
| Nome | Comparar modelo e gerar DDL |
| Ator Principal | AT-001 |
| Pré-condições | Entidades registradas; conexão alvo acessível. |
| Pós-condições | Banco alterado conforme o modelo. |
| Trigger | Execução do `TModelDbCompare`. |

**Fluxo Principal:**
1. Cria `TModelDbCompare.Create(ConnTarget)`.
2. O framework extrai o metadata das classes e do banco.
3. Compara e executa os comandos DDL.

**Fluxo de Exceção:**
- 2a. Sem conexão: "Não foi possivel fazer conexão com o banco de dados Target".
- 3a. Erro em comando: exceção com o aviso do comando e a mensagem original.

---

### UC-008: Gerar classes de modelo a partir do banco

| Campo | Valor |
|---|---|
| ID | UC-008 |
| Nome | Engenharia reversa de tabelas para units |
| Ator Principal | AT-006 |
| Pré-condições | Banco acessível via FireDAC. |
| Pós-condições | Units `.pas` de modelo geradas na pasta indicada. |
| Trigger | Abertura do ORMBrGeneratorModel. |

**Fluxo Principal:**
1. O usuário cadastra uma conexão (tipo, servidor, porta, banco, schema, usuário, senha), salva em `Connection.xml`.
2. Seleciona a conexão e clica em Conectar.
3. A lista de tabelas é carregada; ao clicar em uma tabela, vê os campos e o código gerado.
4. Informa o nome do projeto e a pasta, marca minúsculas/lazy e clica em "Reverse All".
5. As units são gravadas.

---

## SEÇÃO 7 — User Stories

| ID | Como... | Quero... | Para que... | Critérios de Aceitação |
|---|---|---|---|---|
| US-001 | desenvolvedor | anotar uma classe e obter CRUD sem escrever SQL | reduzir código repetitivo de acesso a dados | - [ ] INSERT/UPDATE/DELETE/SELECT gerados para o dialeto da conexão<br>- [ ] PK preenchida após o insert |
| US-002 | desenvolvedor | que só os campos alterados entrem no UPDATE | evitar sobrescrever dados de outros usuários e reduzir tráfego | - [ ] UPDATE não é emitido se nada mudou<br>- [ ] Campos `NoUpdate` nunca entram |
| US-003 | desenvolvedor | gravar mestre e detalhes numa única chamada | garantir consistência do documento | - [ ] Tudo em uma transação<br>- [ ] Detalhes removidos da lista são excluídos |
| US-004 | desenvolvedor | trocar o banco mudando só a unit do gerador e o driver | manter o mesmo código em vários SGBDs | - [ ] Mesma aplicação roda em Firebird e PostgreSQL sem alterar o modelo |
| US-005 | desenvolvedor | aplicar um filtro global (ex.: multiempresa) a uma entidade | não repetir o WHERE em cada consulta | - [ ] Escopo aparece em `Find`, `FindWhere` e paginação |
| US-006 | desenvolvedor | publicar minhas entidades como API REST em poucas linhas | expor dados a outros sistemas | - [ ] GET/POST/PUT/DELETE funcionando com `$filter`, `$top`, `$skip` |
| US-007 | desenvolvedor | ver o SQL gerado e seus parâmetros | depurar problemas de mapeamento | - [ ] Monitor exibe comando e parâmetros a cada execução |
| US-008 | desenvolvedor | gerar os modelos a partir de um banco existente | migrar sistemas legados para o ORM | - [ ] Uma unit por tabela com PK, colunas e tipos corretos |

---

## SEÇÃO 8 — Regras de Negócio

| ID | Descrição | Origem |
|---|---|---|
| RN-001 | Toda entidade persistida precisa de `[PrimaryKey]`; UPDATE, DELETE, cascata e controle de estado falham sem ela. | `cMESSAGEPKNOTFOUND` — ObjectSet, Updater, Deleter |
| RN-002 | Toda entidade precisa ter ao menos um `[Column]` para gerar INSERT. | `cMESSAGECOLUMNNOTFOUND` — `TCommandInserter` |
| RN-003 | Propriedades com valor nulo não entram no INSERT. | `GeneratorInsert`, `GenerateInsert` |
| RN-004 | Colunas `NoInsert` não entram no INSERT; colunas `NoUpdate` não entram no UPDATE nem na comparação de alterações. | `TCommandInserter`, `TCommandUpdater`, `ModifyFieldsCompare` |
| RN-005 | Colunas `VirtualData` e `JoinColumn` não são gravadas; `JoinColumn` é lida apenas via JOIN. | `GetCriteriaSelect`, `GenerateInsert` |
| RN-006 | Só se gera UPDATE quando a lista de campos alterados não está vazia. | `TCommandUpdater.GenerateUpdate`, `_UpdateInternal` |
| RN-007 | A detecção de alteração em BLOB compara apenas o tamanho do conteúdo. [INFERIDO] | `ModifyFieldsCompare` (`ToSize`) |
| RN-008 | PK com `SequenceInc` obtém o próximo valor da sequência/generator antes do INSERT. | `GeneratorAutoIncNextValue` |
| RN-009 | PK GUID: `Guid32Inc` sem hífens nem chaves; `Guid36Inc` sem hífens, com chaves; `Guid38Inc` formato completo `{...}`. | `TCommandInserter` (Guid36 remove só hífens, o que resulta em 34 caracteres) [INFERIDO] |
| RN-010 | Booleanos são gravados como inteiro 0/1, exceto no PostgreSQL. | `TCommandInserter`, `TCommandUpdater` |
| RN-011 | Se a aplicação já abriu uma transação, o ORM não faz commit nem rollback; caso contrário, controla a própria transação. | `TObjectSetAdapter`, `ApplyUpdates` |
| RN-012 | Se a conexão estava fechada, o ORM conecta para a operação e desconecta ao final. | Adapters ObjectSet/DataSet |
| RN-013 | A cascata só ocorre para as ações listadas em `[CascadeActions]` (Insert, Update, Delete, AutoInc). | `CascadeActionsExecute` |
| RN-014 | Na exclusão em cascata, os filhos são excluídos antes do pai (recursivamente). | `OneToMany/OneToOneCascadeActionsExecute` |
| RN-015 | No UPDATE em cascata, filho sem estado anterior é tratado como novo e inserido. | `OneToManyCascadeActionsExecute` |
| RN-016 | No UPDATE mestre-detalhe, filhos que existiam no estado original e não estão mais na lista são excluídos. | `TObjectSetAdapter.Update` |
| RN-017 | A PK gerada no mestre é copiada para as FKs dos filhos quando há `CascadeAutoInc`. | `SetAutoIncValueChilds` |
| RN-018 | Associações não são carregadas nem processadas no MongoDB. | `FillAssociation` (`dnMongoDB`) |
| RN-019 | Associações lazy não são carregadas no `Find`; só via `LoadLazy`. | `FillAssociation` |
| RN-020 | Campos `NotNull` (exceto `NoInsert`, `NoUpdate`, `JoinColumn`, `NoValidate`, `Nullable` e tipos DataSet/ADT/Blob) são validados antes do Post. | `ExecuteCheckNotNull` |
| RN-021 | Se a coluna declara eventos obrigatórios (`OnSetText`, `OnGetText`, `OnChange`, `OnValidate`), o campo do DataSet precisa tê-los atribuídos. | `_ValideFieldEvents` |
| RN-022 | Ao excluir um registro mestre no DataSet, os DataSets filhos e aninhados são esvaziados/excluídos. | `DoBeforeDelete` |
| RN-023 | Paginação só é aplicada quando `APageSize > -1`; após uma página vazia, novas buscas são suspensas. | `GeneratorPageNext`, `FetchingRecords` |
| RN-024 | Não se pode registrar dois campos calculados ou agregados com o mesmo nome. | `ormbr.dataset.fields` |
| RN-025 | Os middlewares e escopos são identificados pelo nome da classe em maiúsculas; o primeiro registro por recurso/nome prevalece. | `AddEvent`, `AddWhere` (`ContainsKey` antes de `Add`) |
| RN-026 | Middlewares são singletons; instanciar diretamente levanta exceção. | `Create` → `raise` |
| RN-027 | No servidor REST, recursos com `[NotServerUse]` não podem ser consultados (GET). | `ParseFind` |
| RN-028 | O DELETE REST exige ID ou `$filter`; sem registro encontrado, retorna erro. | `ParseDelete` |
| RN-029 | O PUT REST localiza o registro pela PK contida no JSON; se não existir, nada é feito e a resposta vem vazia. [INFERIDO] | `ParseUpdate` |
| RN-030 | Operadores OData (`eq`, `ne`, `gt`, `ge`, `lt`, `le`, `add`, `sub`, `mul`, `div`) são convertidos em operadores SQL. | `ParseOperator` |
| RN-031 | Enumerações só podem ser mapeadas como `ftBoolean`, `ftInteger`, `ftFixedChar` ou `ftString`. | `cENUMERATIONSTYPEERROR` |
| RN-032 | `TManagerDataSet` exige que `USEFDMEMTABLE` ou `USECLIENTDATASET` esteja definido em `ormbr.inc`. | `ResolverDataSetType` |
| RN-033 | `TSQLCommandExecutor` só pode ser criado por uma Session; instanciar direto levanta exceção. | `TSQLCommandExecutor.Create` |
| RN-034 | `NestedList<T>` só pode ser usado com `OwnerNestedList = True`. | `TManagerObjectSet.NestedList` |

---

## SEÇÃO 9 — Fluxos de Tela e Navegação

O ORMBr é uma biblioteca; o núcleo não tem telas de negócio. As telas existentes pertencem às ferramentas auxiliares e ao monitor. Os 68 `.dfm` e 3 `.fmx` restantes são de projetos de exemplo.

### Mapa de Navegação

```
[ORMBr Install — assistente]
    └─► [Início]
            └─► [Configuração: pasta destino, versões Delphi, Win32/Win64, FDMemTable|ClientDataSet]
                    └─► [Pacotes: seleção dos pacotes REST]
                            └─► [Instalação: progresso + log]
                                    └─► [Finalizar]

[ORMBr Generator Model]
    ├─► [Cadastro de Conexões (Frm_Connection)] ──► Connection.xml
    └─► [Principal]
            ├─► [Lista de Tabelas] ─► [Lista de Campos] ─► [Código gerado]
            └─► [Reverse All] ─► units .pas na pasta destino

[Command Monitor (runtime, singleton)]
    └─► [Memo de SQL + parâmetros] ─► [Limpar]
```

### Descrição de Telas

#### Tela: ORMBr Install (`uPrincipal`)
- **Propósito:** instalar os pacotes do ORMBr na IDE.
- **Campos:** diretório de destino (texto, obrigatório), versões do Delphi (checklist), Win32/Win64 (checkbox), FDMemTable/ClientDataSet (radio), "deixar somente LIB" (checkbox), usar arquivo de configuração (checkbox).
- **Ações:** Selecionar diretório, Instalar (compila os pacotes), Visualizar log, Avançar/Cancelar/Finalizar.
- **Validações:** Não identificado no código-fonte em detalhe.
- **Requisitos relacionados:** RF-053.

#### Tela: Gerador de Modelos (`Frm_Principal`)
- **Propósito:** gerar classes de modelo a partir do banco.
- **Campos:** conexão (combo), projeto (texto), caminho (texto), minúsculas (checkbox), lazy (checkbox).
- **Ações:** Conectar, clicar em tabela (exibe código), Reverse All (gera todas as units).
- **Validações:** Não identificado no código-fonte.
- **Requisitos relacionados:** RF-052.

#### Tela: Cadastro de Conexões (`Frm_Connection`)
- **Propósito:** manter as conexões do gerador.
- **Campos:** tipo (MSSQL, FB, MySQL, SQLite, PG, Oracle, DB2, IB), nome, servidor, porta, banco, schema, usuário, senha.
- **Ações:** navegação/edição via DBNavigator; gravação em `Connection.xml`.
- **Validações:** Não identificado no código-fonte.
- **Requisitos relacionados:** RF-052. Ver risco R-08.

#### Tela: Command Monitor (`ormbr.form.monitor`)
- **Propósito:** exibir os comandos SQL enviados ao banco.
- **Campos:** memo (somente leitura).
- **Ações:** botão para limpar. [INFERIDO]
- **Requisitos relacionados:** RF-010, RF-051.

---

## SEÇÃO 10 — Modelo de Dados

O ORMBr não tem um modelo de dados próprio: ele mapeia o modelo da aplicação. Esta seção descreve (a) o meta-modelo de mapeamento e (b) o modelo de referência usado nos exemplos.

### 10.1 Entidades Principais

**(a) Meta-modelo de mapeamento (atributos DBCBr usados pelo ORMBr)**

| Elemento | Descrição | Atributos Principais |
|---|---|---|
| `[Entity]` / `[Table]` | Marca a classe como persistente e define a tabela. | nome da tabela, descrição |
| `[PrimaryKey]` | Chave primária. | colunas, `TAutoIncType`, `TGeneratorType` (NoneInc, SequenceInc, Guid32Inc, Guid36Inc, Guid38Inc), ordenação, descrição |
| `[Sequence]` | Sequência/generator da PK. | nome, incremento |
| `[Column]` | Coluna da tabela. | nome, `TFieldType`, tamanho, precisão, escala |
| `[Restrictions]` | Restrições de gravação/validação. | `NotNull`, `NoInsert`, `NoUpdate`, `NoValidate`, `Unique`, `Hidden`, `VirtualData` |
| `[Dictionary]` | Metadados de UI e validação. | label, mensagem de constraint, valor padrão, máscara, alinhamento |
| `[ForeignKey]` | FK física. | nome, coluna, tabela referenciada, coluna referenciada |
| `[JoinColumn]` | Coluna obtida por JOIN (somente leitura). | coluna local, tabela, coluna ref., coluna exibida, tipo de JOIN |
| `[Association]` | Relacionamento entre objetos. | `TMultiplicity` (OneToOne, ManyToOne, OneToMany, ManyToMany), colunas, classe ref., colunas ref., lazy |
| `[CascadeActions]` | Ações em cascata. | CascadeInsert, CascadeUpdate, CascadeDelete, CascadeAutoInc |
| `[OrderBy]` / `[Indexe]` / `[Check]` | Ordenação padrão, índices, checks. | colunas |
| `[Enumeration]` | Mapeamento de enum. | `TEnumType`, valores |
| `[AggregateField]` | Campo agregado no DataSet. | nome, expressão |
| `[NotServerUse]` | Bloqueia a exposição REST da entidade. | — |
| `[Resource]` / `[SubResource]` | Nome do recurso REST. | nome |
| `[LiveBindingsControl]` | Liga propriedade a controle visual. | controle, campo, expressão |

**(b) Modelo de referência dos exemplos (`Examples/Data/Models`)**

| Entidade | Descrição | Atributos Principais |
|---|---|---|
| `Tmaster` (master) | Documento mestre | master_id (PK, sequência), description (Nullable), registerdate, updatedate, client_id (FK), MyEnum, client_name (JoinColumn), client (1:1), detail (1:N, cascata total), total (calculado) |
| `Tdetail` (detail) | Itens do mestre | detail_id, master_id (FK), lookup_id, preço/quantidade [INFERIDO] |
| `Tclient` (client) | Cliente | client_id, client_name, client_foto (TBlob) |
| `Tlookup` (lookup) | Tabela de lookup | lookup_id, lookup_description |

### 10.2 Relacionamentos

```
[client] 1 ──── N [master]          (master.client_id → client.client_id; JOIN para client_name)
[master] 1 ──── N [detail]          (CascadeInsert/Update/Delete/AutoInc)
[detail] N ──── 1 [lookup]          (lookup field no DataSet)
```

### 10.3 Tabelas / Estruturas de Dados

Estruturas internas relevantes do framework:

| Estrutura | Unit | Finalidade |
|---|---|---|
| `TRepositoryList = TObjectDictionary<string, TRepository>` | `ormbr.manager.objectset` | Adapter e lista aninhada por nome de classe. |
| `FObjectState: TObjectDictionary<string, TObject>` | `ormbr.objectset.base.adapter` | Cópia do estado original; chave = `Classe-PK1-PK2...`. |
| `FModifiedFields: TDictionary<string, TDictionary<string,string>>` | `ormbr.session.abstract` | Campos alterados por objeto (propriedade → coluna). |
| `FDeleteList: TObjectList<M>` | `ormbr.session.abstract` | Registros excluídos aguardando `ApplyUpdates`. |
| `TQueryCache` | `ormbr.dml.cache` | Cache de SQL por classe (`Classe` e `Classe-INSERT`). |
| `TDriverRegister.FDriver: TDictionary<TDriverName, IDMLGeneratorCommand>` | `ormbr.driver.register` | Gerador de dialeto por driver. |
| `TORMBrMiddlewares` | `ormbr.register.middleware` | Callbacks de eventos e escopos por nome. |
| `Nullable<T>`, `TBlob`, `Lazy<T>` | `ormbr.types.*` | Tipos de valor usados nas propriedades das entidades. |

---

## SEÇÃO 11 — Integrações Externas

| ID | Sistema Externo | Tipo | Protocolo | Direção | Descrição |
|---|---|---|---|---|---|
| INT-001 | Firebird / Firebird 3 / InterBase | SGBD | via DBEBr (FireDAC, Zeos, UniDAC, IBExpress, DBExpress, ADO, SQLDirect, FIBPlus, IBObjects) | Entrada/Saída | Dialeto `FIRST/SKIP`, `GEN_ID`. |
| INT-002 | MySQL | SGBD | idem | Entrada/Saída | `LIMIT/OFFSET`. |
| INT-003 | PostgreSQL | SGBD | idem | Entrada/Saída | `LIMIT/OFFSET`; booleano nativo. |
| INT-004 | SQLite | SGBD | idem / SQLite3 nativo (`Source/External/SQLite3`) | Entrada/Saída | `LIMIT/OFFSET`. |
| INT-005 | MS SQL Server | SGBD | idem | Entrada/Saída | Paginação específica do dialeto. |
| INT-006 | Oracle | SGBD | idem | Entrada/Saída | Paginação específica do dialeto. |
| INT-007 | NexusDB, ElevateDB, AbsoluteDB, Advantage (ADS) | SGBD | idem | Entrada/Saída | `TOP` / `FIRST/SKIP`. |
| INT-008 | MongoDB | NoSQL | FireDAC Mongo ou MongoWire (`Components/Source/MongoWire`) | Entrada/Saída | Gerador NoSQL; associações ignoradas. |
| INT-009 | Horse | Framework REST | HTTP | Entrada (servidor) / Saída (cliente) | Servidor, cliente, middleware `Horse.ORMBr`, Swagger. |
| INT-010 | DataSnap | Framework REST | HTTP | Entrada/Saída | Servidor e cliente. |
| INT-011 | Delphi MVC Framework | Framework REST | HTTP | Entrada/Saída | Servidor e cliente. |
| INT-012 | MARS Curiosity | Framework REST | HTTP | Entrada/Saída | Servidor e cliente. |
| INT-013 | WiRL | Framework REST | HTTP | Entrada/Saída | Servidor e cliente. |
| INT-014 | WebService genérico | API REST | HTTP/HTTPS | Saída | Cliente `ormbr.client.ws`. |
| INT-015 | GBSwagger | Biblioteca | — | Saída | Documentação OpenAPI dos recursos Horse. |
| INT-016 | GitHub (HashLoad) | Repositório | HTTPS | Entrada | Download de dependências (ORMBr Dependencies) e Boss. |
| INT-017 | DBCBr / DBEBr / CQLBr / JSONBr | Bibliotecas obrigatórias | — | — | Mapeamento, conexão, SQL e JSON. |

---

## SEÇÃO 12 — Restrições e Premissas

### 12.1 Restrições Técnicas
- **Delphi versão mínima:** XE (VER220), segundo o README. Desde 24/11/2026 o `ormbr.inc` deriva os símbolos de versão de `CompilerVersion` e cobre o Delphi 13 (VER370, `CompilerVersion` 37) e versões posteriores. As dependências ainda param no VER360 (ver Anexo A do plano de compatibilidade).
- **Banco de dados:** qualquer um dos 14 dialetos registrados (Seção 11).
- **Sistema operacional:** Windows (Win32/Win64) como alvo principal; componentes declaram suporte a macOS e Linux. Uso em mobile via FMX é possível. [INFERIDO]
- **Dependências obrigatórias:** DBCBr ^1.1.7, DBEBr ^1.1.7, CQLBr ^1.1.6, JSONBr ^1.1.6 (`boss.json`). Não estão versionadas neste repositório (`Source/Dependencies/*` só tem readme).
- **Dependências opcionais:** FireDAC (FDMemTable), DBClient (ClientDataSet), Horse, DataSnap, DMVC, MARS, WiRL, GBSwagger, JVCL (instalador).
- **Diretivas de compilação** (`Source/ormbr.inc`): `VCL` e `USEFDMEMTABLE` ativos por padrão; `FMX`, `DRIVERRESTFUL`, `USECLIENTDATASET` e `MONITORRESTFULCLIENT` desativados.
- **Uso de RTTI estendido e genéricos** em todas as camadas.

### 12.2 Premissas
- A unit do gerador de dialeto (`ormbr.dml.generator.<banco>`) está na cláusula `uses` do projeto; sem ela, o driver não fica registrado.
- As entidades são registradas (`TRegisterClass.RegisterEntity`) antes do primeiro uso.
- O nome da classe Delphi é usado como chave de repositório, middleware e recurso REST; classes homônimas em units diferentes colidem. [INFERIDO]
- Cláusulas `Where`/`OrderBy` passadas à API vêm de código confiável, e não da entrada direta do usuário final. [INFERIDO]
- O servidor REST fica atrás de uma camada de autenticação própria da aplicação, já que o ORMBr não autentica. [INFERIDO]

### 12.3 Riscos e inconsistências identificados no código

Pontos que precisam de validação, encontrados durante a análise. Nenhum foi confirmado com execução.

| ID | Severidade | Descrição | Local |
|---|---|---|---|
| R-01 | Alta | `$filter` da URL REST é repassado ao `FindWhere` como SQL bruto; o `ParseOperator` só troca operadores. Há risco de **SQL injection** no servidor REST. | `ormbr.server.resource.pas` (`ResolverFindFilter`, `ParseDelete`) |
| R-02 | Média | Valores de ID e de associação são concatenados no SQL (`QuotedStr` para strings, direto para inteiros), e não parametrizados. | `GetGeneratorWhere`, `GenerateSelectOneToOne/Many` |
| R-03 | Alta | Com Query Scope registrado, `GeneratorSelectWhere` faz `Result := ' WHERE ' + LScopeWhere` e `Result := ' ORDER BY ' + LScopeOrderBy`, **sobrescrevendo** o SELECT já montado. Provavelmente gera SQL inválido em `FindWhere`/`OpenWhere` quando há escopo. | Todos os `ormbr.dml.generator.*.pas` e `ormbr.dml.generator.pas` (linhas 318/397) |
| R-04 | Média | O gerador do ElevateDB se registra como `dnAbsoluteDB`, substituindo o gerador AbsoluteDB quando as duas units são usadas. | `ormbr.dml.generator.elevatedb.pas:184` |
| R-05 | Média | `ParseOperator` usa `StringReplace` sem limite de palavra: nomes de campo e valores com `eq`, `ne`, `add`, `div`, `le` etc. são corrompidos (ex.: `address` → `+ress`, `title` → `tit<=`). | `ormbr.server.restquery.parse.pas` |
| R-06 | Média | `[NotServerUse]` é verificado só no GET; POST, PUT e DELETE não checam a permissão. | `ormbr.server.resource.pas` |
| R-07 | Baixa | `TManagerObjectSet.Prior<T>` só decrementa se `FCurrentIndex > Count-1` (nunca no uso normal); `Bof<T>` retorna `True` no último índice. | `ormbr.manager.objectset.pas` |
| R-08 | Média | O Gerador de Modelos grava usuário e **senha em texto puro** em `Connection.xml`, ao lado do executável, e esse arquivo está no repositório. | `Projects/Gerador Modelo/Frm_Principal.pas` (`SaveConnection`) |
| R-09 | Baixa | Erros no servidor Horse são devolvidos no corpo com status HTTP 200. | `ormbr.server.horse.pas` |
| R-10 | Baixa | Os adapters relançam erros com `Exception.Create(E.Message)`, perdendo a classe original da exceção (ex.: erros específicos do driver). | `TObjectSetAdapter`, adapters DataSet |
| R-11 | Baixa | A detecção de alteração em BLOB compara só o tamanho; conteúdo diferente com o mesmo tamanho não é gravado. | `ModifyFieldsCompare` |
| R-12 | Baixa | Limite fixo de 300.000 registros no FDMemTable. | `ormbr.dataset.fdmemtable.pas` |

---

## SEÇÃO 13 — Critérios de Aceitação Global

O framework será considerado conforme esta SPEC quando:

- [ ] Todos os requisitos de prioridade Alta (RF-001 a RF-007, RF-009, RF-011, RF-013 a RF-019, RF-023 a RF-026, RF-029, RF-038, RF-039, RF-041, RF-042, RF-045) estiverem cobertos por testes automatizados.
- [ ] CRUD completo (UC-002) e master-detail (UC-003) passarem em ao menos Firebird, PostgreSQL, MySQL, SQLite e MS SQL Server.
- [ ] Consultas com Query Scope gerarem SQL válido em todos os dialetos (risco R-03).
- [ ] O servidor REST rejeitar `$filter` com SQL arbitrário e aplicar `[NotServerUse]` a todos os verbos (R-01, R-06).
- [ ] Cada dialeto se registrar com o próprio `TDriverName` (R-04).
- [ ] Uma suíte DUnitX cobrir ao menos 70% das units de `Source/Core`, `Source/Objectset` e `Source/Dataset` (hoje não há testes).
- [ ] Os pacotes compilarem em todas as versões de Delphi suportadas (RNF-001).
- [ ] Aprovação formal dos mantenedores do projeto.

---

## SEÇÃO 14 — Histórico de Revisões

| Versão | Data | Autor | Descrição da Alteração |
|---|---|---|---|
| 1.0 | 24/11/2026 | delphi-spec (geração automática) | Versão inicial, por engenharia reversa do código-fonte do ORMBr 1.1.8 |
| 1.1 | 24/11/2026 | Claude Code | RNF-001 e 12.1 atualizados para o Delphi 13 (plano `docs/planos/2026-11-24-compatibilidade-delphi-13.md`) |

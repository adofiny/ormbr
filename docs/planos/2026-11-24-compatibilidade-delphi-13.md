# Plano — Compatibilidade do ORMBr com Delphi 13 (Florence)

| Campo | Valor |
|---|---|
| Data | 24/11/2026 |
| Solicitação | Adaptar o ORMBr para compilar e rodar no Delphi 13. Hoje compila no Delphi 12, mas não no 13. |
| Escopo aprovado | Runtime (`Source/`). Pacotes da IDE, instalador, Gerador de Modelo e exemplos ficam fora. |
| Plataformas | Win32, Win64, Android e iOS (FMX) |
| Estratégia do `ormbr.inc` | Torná-lo à prova de futuro com `{$IF CompilerVersion >= N}`, mantendo os símbolos `DELPHInn_UP` atuais |
| Dependências (DBCBr, DBEBr, CQLBr, JSONBr) | Fora do projeto. Não serão alteradas por este plano; ver **Anexo A** |

---

## Diagnóstico

O que foi verificado na máquina e no código, sem compilar ainda:

1. **O Delphi 13 está instalado** em `C:\Program Files (x86)\Embarcadero\Studio\37.0`. Os BPLs usam o sufixo `370` (`rtl370.bpl`) e os fontes do Indy da própria instalação definem `VER370` como "Delphi & CBuilder 13.0 Florence". Conclusão: `CompilerVersion = 37`, símbolo `VER370`.
2. **`Source/ormbr.inc` só conhece até `VER360`** (Delphi 12). No Delphi 13 nenhum símbolo `DELPHInn_UP` é definido, e os símbolos derivados também não:
   - `FORMATSETTINGS` (depende de `DELPHI15_UP`)
   - `HAS_NET_ENCODING` (depende de `DELPHI17_UP`)
3. Efeito disso nas units (20 delas incluem `ormbr.inc`):
   - `Source/Core/ormbr.types.blob.pas` cai no ramo `HAS_ENCDDECD`, que usa `encddecd` sem namespace e referencia a variável **`AString`, que não existe** em `GetDecodeBase64` (linha 467; o parâmetro se chama `Value`). **Erro de compilação garantido.** O ramo `HAS_SOAP_ENCODING` tem o mesmo erro (linha 452). Os dois só compilam hoje porque o Delphi 12 usa o terceiro ramo, `HAS_NET_ENCODING`.
   - `ormbr.json.pas`, `ormbr.client.datasnap.pas`, `ormbr.client.horse.pas`, `ormbr.client.ws.pas` e `ormbr.session.restful.pas` passam a usar `DBXJSON` em vez de `JSON`. `Data.DBXJSON` ainda existe no Delphi 13, mas tem classes diferentes de `System.JSON`; isso deve gerar incompatibilidade de tipos com o JSONBr.
4. **Nenhuma das 4 dependências conhece `VER370`**, nem na cópia local (cache do Boss, versões 1.1.6–1.1.51) nem no `master` atual do GitHub. Nelas o problema é **silencioso**:
   - `dbcbr.rtti.helper.pas:628` — sem `DELPHI22_UP`, os tipos `tkAnsiString`, `tkUnicodeString` etc. deixam de ser reconhecidos (erro de comportamento em runtime, não de compilação).
   - `jsonbr.builders.pas:652/745` — sem `DELPHI15_UP`, a serialização de listas cai num ramo legado com cast para `TList`.
   - Atualizar pelo Boss **não resolve**, porque o upstream ainda não foi corrigido.
5. **Mobile:** `ormbr.inc` liga `VCL` por padrão. Em Android/iOS isso puxa `Graphics`, `GIFImg`, `JPEG` e `PngImage` (VCL) em `ormbr.types.blob.pas`. Units que só fazem sentido no Windows: `Source/Monitor/ormbr.form.monitor.pas`, `Source/Livebindings/ormbr.vcl.controls.pas` e `Source/External/SQLite3/*`.
6. **Compiladores disponíveis no Delphi 13:** `dcc32`, `dcc64`, `dccaarm64`, `dcciosarm64` (entre outros). O Delphi 12 (`Studio\23.0`) continua instalado e serve para teste de regressão.
7. A docwiki da Embarcadero recusou acesso automatizado (HTTP 403). Os fatos acima vieram da instalação local. Ver pendência P-01.

**Ainda não confirmado:** a lista real de erros do Delphi 13. O Sprint 1 existe para obtê-la antes de qualquer correção.

---

## Sprint 1 — Baseline reproduzível de compilação

**Objetivo:** ter uma forma repetível de compilar todo o `Source/` em qualquer versão e plataforma, e registrar os erros reais do Delphi 13.
**Concluído quando:** o check passar no Delphi 12 Win32 e a lista de erros do Delphi 13 estiver registrada.

### Fase 1.1 — Ferramenta de verificação

**T1.1.1 — Criar o projeto de verificação de compilação**
- **Ação:** criar `Projects/CompileCheck/` contendo:
  - `ORMBrCompileCheck.dpr`: programa console que lista nos `uses` todas as units de `Source/` que dependem só da RTL e das 4 dependências. Units exclusivas do Windows (`ormbr.form.monitor`, `ormbr.vcl.controls`, `External/SQLite3/*`) entram dentro de `{$IFDEF MSWINDOWS}`.
  - `compile-check.ps1`: recebe a versão do Delphi (`23.0` ou `37.0`), a plataforma (`Win32`, `Win64`, `Android64`, `iOSDevice64`) e a pasta-raiz das dependências.
    - Win32/Win64: compila o `.dpr` com `dcc32`/`dcc64`.
    - Android64/iOSDevice64: compila **unit por unit até `.dcu`, sem link**, com `dccaarm64`/`dcciosarm64`. Assim não é preciso SDK/NDK configurado.
  - A saída de `.dcu` vai para `Projects/CompileCheck/dcu/<versão>/<plataforma>/`, dentro do projeto. Nada é gravado fora dele.
- **Fora do check:** units de servidor e cliente REST que dependem de frameworks de terceiros (Horse, DMVC, MARS, WiRL, DataSnap Server, GBSwagger). Elas ficam listadas no cabeçalho do `.dpr` como "não verificadas", e o motivo é informado.
- **Arquivos:** `Projects/CompileCheck/ORMBrCompileCheck.dpr`, `Projects/CompileCheck/compile-check.ps1`, `.gitignore` (adicionar `Projects/CompileCheck/dcu/`).
- **Dependências:** nenhuma.
- **Risco:** baixo (arquivos novos, nenhuma unit existente é alterada).
- **Padrões:** o `.dpr` começa com o cabeçalho LGPL do projeto (convenção do `CLAUDE.md`). O script só lê as dependências na pasta informada; toda escrita fica em `Projects/CompileCheck/`.
- **Validação:** `compile-check.ps1 -Delphi 23.0 -Platform Win32` termina com 0 erros no Delphi 12. Guardar a lista de **avisos** do Delphi 12 como referência para o TF.1.

**T1.1.2 — Registrar o baseline do Delphi 13**
- **Ação:** rodar o check no Delphi 13 nas 4 plataformas e anexar a este plano (seção "Baseline Delphi 13") cada erro e aviso novo, com a unit, a linha e a origem (ORMBr ou dependência).
- **Dependências:** T1.1.1.
- **Risco:** nenhum (só leitura e registro).
- **Validação:** a lista existe e cada item está classificado como "ORMBr", "dependência" ou "configuração".

---

## Sprint 2 — Correções no ORMBr

**Objetivo:** o `Source/` compila no Delphi 13 Win32/Win64 sem regredir o Delphi 12.
**Concluído quando:** o check passar com 0 erros em Delphi 12 Win32 e Delphi 13 Win32/Win64, considerando que o Anexo A já foi aplicado nas dependências.

### Fase 2.1 — `ormbr.inc` à prova de futuro

**T2.1.1 — Trocar os blocos `VERnnn` por uma cascata de `CompilerVersion`** ⚠️ *Risco: incluído por 20 units*
- **Ação:** em `Source/ormbr.inc`, substituir os blocos `{$IFDEF VER210}` … `{$IFDEF VER360}` por uma cascata equivalente:
  ```pascal
  {$IF CompilerVersion >= 21.0} {$DEFINE DELPHI14_UP} {$IFEND}
  {$IF CompilerVersion >= 22.0} {$DEFINE DELPHI15_UP} {$IFEND}
  ...
  {$IF CompilerVersion >= 36.0} {$DEFINE DELPHI29_UP} {$IFEND}
  {$IF CompilerVersion >= 37.0} {$DEFINE DELPHI30_UP} {$IFEND}
  ```
  - Mantém exatamente os mesmos símbolos para Delphi 2010 até 12 (regra: `DELPHInn_UP` com `nn = CompilerVersion − 7`).
  - Acrescenta `DELPHI30_UP` (Delphi 13). Versões futuras herdam todos os símbolos anteriores sem nova edição.
  - Envolve a cascata em `{$IFNDEF FPC}`, porque o Free Pascal não define `CompilerVersion`.
  - O bloco do Lazarus (`{$IFDEF FCP}`, linha 279) fica como está. Ele tem um erro de digitação (deveria ser `FPC`), mas Lazarus está fora do escopo; só registrar como observação.
  - Atualiza a tabela de versões no comentário: `Delphi 13 Florence | 37 | VER370 | 370`.
  - Os blocos derivados (`FORMATSETTINGS`, `HAS_NET_ENCODING` etc.) ficam como estão.
- **Encoding:** o arquivo é ANSI (Windows-1252). A edição precisa preservá-lo.
- **Antes de editar:** listar os usos de cada símbolo `DELPHInn_UP` e `HAS_*` em `Source/` e conferir que nenhum muda de valor no Delphi 12.
- **Dependências:** T1.1.2.
- **Validação:** check verde no Delphi 12 Win32 (regressão) e no Delphi 13 Win32.

**T2.1.2 — Selecionar FMX automaticamente fora do Windows** ⚠️ *Risco: incluído por 20 units*
- **Ação:** em `Source/ormbr.inc`, antes da derivação de `HAS_VCL`/`HAS_FMX`:
  ```pascal
  {$IFNDEF MSWINDOWS}
    {$UNDEF VCL}
    {$DEFINE FMX}
  {$ENDIF}
  ```
  No Windows, o padrão VCL continua igual.
- **Usos já levantados na revisão:** `HAS_VCL`/`HAS_FMX` só são testados em `Source/Core/ormbr.types.blob.pas` (linhas 38, 41, 70, 86, 179, 265). `ormbr.controls.helpers.pas:29` testa `HAS_FMX`, mas não inclui `ormbr.inc`, então não é afetado. Reconfirmar com grep antes de editar.
- **Dependências:** T2.1.1.
- **Validação:** check Android64 sem erros de `Graphics`/`GIFImg`/`JPEG`/`PngImage`, e check Win32 sem mudanças.

### Fase 2.2 — Ramos legados quebrados

**T2.2.1 — Corrigir os ramos `HAS_SOAP_ENCODING` e `HAS_ENCDDECD` de `ormbr.types.blob.pas`**
- **Ação:** nas duas versões de `GetDecodeBase64` (linhas 452 e 467), trocar o identificador inexistente `AString` pelo parâmetro `Value`. Depois do T2.1.1 o Delphi 13 já usa `System.NetEncoding`; esta correção elimina dois ramos que hoje não compilam em nenhuma versão.
- **Arquivo:** `Source/Core/ormbr.types.blob.pas` (ANSI).
- **Dependências:** T2.1.1.
- **Risco:** baixo.
- **Validação:** check Win32 nos Delphi 12 e 13; teste manual de Base64 (ver checklist).

### Fase 2.3 — Erros restantes do baseline

**T2.3.1 — Corrigir, um por um, os erros classificados como "ORMBr" no baseline (T1.1.2) que sobrarem depois da Fase 2.1**
- **Ação:** para cada erro, aplicar a menor correção possível, sempre sob `{$IF CompilerVersion …}` quando o comportamento precisar diferir entre versões. Cada correção vira uma subtarefa registrada neste plano antes de ser aplicada (unit, linha, causa, correção).
- **Padrões das correções:** o código novo não introduz `with`, `Break`, `Continue`, `Exit` fora de guard clause, `Real`, SQL concatenado nem `RecordCount` como teste de existência. Os usos que já existem nas linhas vizinhas (hoje há 14 `with`, 112 `Continue` e 10 `Break` em `Source/`) **não são reescritos** neste plano.
- **Limite:** sem refatorações oportunistas. Problemas de qualidade fora do escopo (ex.: riscos R-01 a R-12 da SPEC) não entram aqui.
- **Arquivos:** só units de `Source/` citadas no baseline.
- **Dependências:** T2.1.1, T2.1.2, T2.2.1.
- **Risco:** marcar ⚠️ em cada subtarefa que tocar `ormbr.bind`, `ormbr.session.abstract`, `ormbr.dataset.base.adapter`, `ormbr.objectset.base.adapter` ou geradores DML (núcleo usado por todas as entidades).
- **Validação:** check verde em Win32/Win64 no Delphi 13 e Win32 no Delphi 12.

---

## Sprint 3 — Plataformas móveis

**Objetivo:** o `Source/` (sem as units exclusivas do Windows) compila para Android64 e iOSDevice64 no Delphi 13.
**Concluído quando:** o check passar com 0 erros nas duas plataformas.

### Fase 3.1 — Android64 e iOSDevice64

**T3.1.1 — Corrigir os erros de mobile do baseline**
- **Ação:** mesmo procedimento da T2.3.1, para os erros que só aparecem em `dccaarm64`/`dcciosarm64`. Tratar com `{$IFDEF MSWINDOWS}` / `{$IFDEF HAS_VCL}` quando o recurso não existir fora do Windows.
- **Dependências:** Sprint 2 concluído.
- **Risco:** médio. Pode exigir guardas novas em `ormbr.types.blob.pas` (imagem) e `ormbr.dataset.clientdataset.pas` (MIDAS).
- **Validação:** check Android64 e iOSDevice64 verdes. A execução real em dispositivo fica para quando houver SDK configurado (ver P-02).

---

## Sprint 4 — Documentação

**Objetivo:** quem clonar o projeto sabe como compilar no Delphi 13.
**Concluído quando:** os três arquivos abaixo estiverem atualizados.

**T4.1.1 — Atualizar `CLAUDE.md`, `README.md` e `SPEC.md`**
- `CLAUDE.md`, seção *Conditional compilation*: a cascata de `CompilerVersion` substitui a instrução "add new compiler versions here"; o `Projects/CompileCheck` passa a ser a forma de validar build; o Anexo A é citado.
- `README.md`, seção *Delphi Versions*: "Delphi XE até Delphi 13", mais a nota de que as dependências precisam do ajuste do Anexo A enquanto o upstream não for corrigido.
- `SPEC.md`: RNF-001 e seção 12.1 passam a citar o Delphi 13 (VER370).
- **Dependências:** Sprints 2 e 3.
- **Risco:** nenhum.
- **Validação:** leitura.

---

## Fase final — Build e teste manual

**TF.1 — Build sem erros** (`delphi-dev:delphi-build`)
- [ ] Delphi 12 — Win32 (regressão)
- [ ] Delphi 13 — Win32
- [ ] Delphi 13 — Win64
- [ ] Delphi 13 — Android64 (somente `.dcu`)
- [ ] Delphi 13 — iOSDevice64 (somente `.dcu`)
- [ ] Nenhum aviso **novo** em relação ao baseline do Delphi 12

**TF.2 — Teste manual no Delphi 13 (Win32), com SQLite via FireDAC**
- [ ] `Examples/Data/FireDAC Sem DataSet`: inserir, alterar (só campos modificados no monitor de SQL), excluir e `Find`/`FindWhere`.
- [ ] `Examples/Data/FireDAC`: master-detail; incluir mestre com 2 detalhes, `ApplyUpdates`, reabrir e conferir.
- [ ] `Examples/Data/Blob`: gravar imagem, reabrir e exibir. Confirma o caminho `System.NetEncoding` (Base64).
- [ ] `Examples/JSON`: objeto → JSON → objeto, inclusive com lista aninhada. Confirma `System.JSON` e o ramo `DELPHI15_UP` do JSONBr, já com o Anexo A aplicado.
- [ ] Campo `string` e `Nullable<string>` gravados e lidos corretamente. Confirma o ramo `DELPHI22_UP` do DBCBr, já com o Anexo A aplicado.
- [ ] Repetir o primeiro item no Delphi 12 (regressão).

---

## Execução — situação em 24/11/2026

| Task | Situação |
|---|---|
| T1.1.1 | Concluída. Além do script, foi criado `ORMBrCompileCheck.dproj` para a IDE, porque o Delphi 12 e o 13 desta máquina não compilam por linha de comando (nem `dcc32` nem MSBuild). |
| T1.1.2 | Substituída: o baseline veio do build do usuário pela IDE. |
| T2.1.1, T2.1.2, T2.2.1 | Concluídas. |
| T2.3.1 | Concluída para Delphi 13 Win32 (1 correção, abaixo). Build Win32 OK no Delphi 13, confirmado pelo usuário, que também recompilou e rodou uma API Horse com o ORMBr atualizado. |
| T3.1.1 | Pendente: exige build Android64/iOSDevice64 pela IDE, com SDK configurado. |
| T4.1.1 | Concluída (`CLAUDE.md`, `README.md`, `SPEC.md`). |
| TF.1 | Delphi 13 Win32 OK. Faltam Delphi 13 Win64, Delphi 12 Win32 (regressão) e mobile. |
| TF.2 | Parcial: API Horse validada pelo usuário. Os itens de JSON e strings dependem do Anexo A. |

## Execução — registro das correções da T2.3.1

| # | Unit / linha | Erro (Delphi 13, Win32) | Causa | Correção |
|---|---|---|---|---|
| 2.3.1-a | `Source/Core/ormbr.dml.generator.nosql.pas:232` | Erro de compilação em `if VarToStr(AID) <> '-1' then` (relatado pelo usuário via IDE) | `AID` é `TValue`, mas era usado como `Variant` (`VarToStr`, `TVarData(AID).VType`, `IntToStr(AID)`). O cast `TVarData(AID)` dependia de os dois records terem o mesmo tamanho. Além disso, o ramo de ID string usava `IntToStr`. | Usa `AID.ToString`, `AID.IsEmpty` e `AID.Kind in [tkInteger, tkInt64]` (unit `TypInfo` adicionada ao `uses`). Ignora ID vazio ou `-1`, como o gerador base. ID string agora sai entre aspas com o valor correto. |

Outras ocorrências do mesmo padrão em `Source/` foram verificadas e estão corretas: `ormbr.bind.pas` (`TField.Value` é `Variant`), `ormbr.rtti.helper.pas` (`AValue` é `Variant`) e `ormbr.session.restful.pas` (`AID` é `Integer`/`Int64`).

---

## Anexo A — Checklist externo das dependências

**Por que é necessário:** as 4 dependências usam o mesmo esquema de `{$IFDEF VERnnn}` e param no `VER360`. No Delphi 13 elas **compilam com comportamento errado** (ver Diagnóstico, item 4). Este plano não as altera porque estão fora de `c:\Componentes\ormbr`.

| Dependência | Arquivo | O que fazer | Onde o problema aparece |
|---|---|---|---|
| DBCBr | `Source/dbcbr.inc` | Aplicar a mesma cascata de `CompilerVersion` da T2.1.1 | `dbcbr.rtti.helper.pas:628` (`DELPHI22_UP`): tipos string não reconhecidos |
| DBEBr | `Source/dbebr.inc` | Idem | Verificar com o check (T1.1.2) |
| CQLBr | `Source/cqlbr.inc` | Idem | Verificar com o check (T1.1.2) |
| JSONBr | `Source/jsonbr.inc` | Idem | `jsonbr.builders.pas:652/745` (`DELPHI15_UP`): serialização de listas |

**Opções para aplicar, a seu critério:**
1. Abrir PR nos repositórios HashLoad e, quando aceitos, subir as versões no `boss.json`.
2. Manter forks próprios e apontar o `boss.json` para eles.
3. Ajustar as cópias locais usadas pelos seus projetos (`modules/` de cada projeto ou cache do Boss), sabendo que um `boss install` sobrescreve.

**Ordem:** o Anexo A precisa estar aplicado **antes** de concluir o Sprint 2, porque o check compila as dependências junto.

**Este anexo não é Task do `/plano-execute`.** O executor não altera nenhum arquivo das dependências. Se o check do Delphi 13 falhar por causa delas, a execução para no fim do Sprint 1 e pede que você aplique o anexo.

---

## Pendências e premissas

| ID | Descrição |
|---|---|
| P-01 | A docwiki (docwiki.embarcadero.com) bloqueou acesso automatizado. Se você tiver em mãos as notas de "breaking changes" do Delphi 13, elas podem antecipar erros do baseline. |
| P-02 | A execução em dispositivo Android/iOS exige SDK/NDK configurado na IDE e está fora do critério de aceite (só compilação). |
| P-03 | Premissa: os projetos consumidores usam os *Unit scope names* padrão do Delphi 13. As units do ORMBr usam nomes sem namespace (`JSON`, `Graphics`, `ZLib`…), que dependem disso. |
| P-04 | Fora do escopo aprovado: pacotes da IDE (`.dpk` e sufixo `370`, IDE 64 bits), instalador e Gerador de Modelo. Pode virar um plano separado. |

---

## Revisão

Revisão feita com `delphi-dev:review` em 24/11/2026, sobre o plano (não sobre código). Os itens ⚠️ já foram incorporados ao texto acima.

| # | Classificação | Ponto | Situação |
|---|---|---|---|
| 1 | ⚠️ ATENÇÃO | T2.1.2 mexe no `ormbr.inc` (incluído por 20 units) sem mandar listar os usos de `HAS_VCL`/`HAS_FMX`. | **Incorporado.** Usos levantados: só `ormbr.types.blob.pas`. |
| 2 | ⚠️ ATENÇÃO | T2.3.1 e T3.1.1 são abertas ("corrigir o que o baseline mostrar") e não diziam o padrão exigido nas correções. O `Source/` já tem 14 `with`, 112 `Continue` e 10 `Break`; sem regra explícita, o executor poderia copiar o estilo vizinho ou reescrever código fora do escopo. | **Incorporado.** Código novo segue os padrões; o existente não é reescrito. |
| 3 | ⚠️ ATENÇÃO | O Sprint 2 depende do Anexo A, que fica fora do projeto. Sem uma regra de parada, o executor poderia tentar "consertar" as dependências. | **Incorporado.** O anexo não é Task; a execução para e pede ação sua. |
| 4 | ⚠️ ATENÇÃO | O TF.1 exige "nenhum aviso novo em relação ao Delphi 12", mas nenhuma Task registrava os avisos do Delphi 12. | **Incorporado** na validação da T1.1.1. |
| 5 | 💡 SUGESTÃO | O `.dpr` novo deve ter o cabeçalho LGPL (convenção do `CLAUDE.md`). | **Incorporado** na T1.1.1. |
| 6 | 💡 SUGESTÃO | Na cascata do `ormbr.inc`, o exemplo põe `{$IF}`, `{$DEFINE}` e `{$IFEND}` na mesma linha. Aceitável para diretivas e mais legível que 17 blocos de 3 linhas; manter, alinhado e com no máximo 120 colunas. | Mantido. |
| 7 | 💡 SUGESTÃO | T2.2.1 altera `ormbr.types.blob.pas` (tipo `TBlob`, usado por entidades com BLOB). A mudança fica em ramos que hoje não compilam, então não altera o comportamento atual. | Sem ação; já coberta pelo teste manual de BLOB. |

**Verificações sem achados:**
- Nenhuma Task induz `Real`, SQL concatenado ou `RecordCount`. O plano não gera SQL.
- Todas as Tasks escrevem só dentro de `c:\Componentes\ormbr`: `Source/`, `Projects/CompileCheck/`, `.gitignore`, `CLAUDE.md`, `README.md`, `SPEC.md` e este plano. O script lê as dependências em pasta externa, mas não escreve nela.
- Nenhuma Task implica commit.
- As units críticas (`ormbr.inc`, `ormbr.types.blob`, núcleo do T2.3.1) estão marcadas com ⚠️ e têm o levantamento de usos previsto antes da edição.

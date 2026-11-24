# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

ORMBr is an attribute/RTTI-based ORM library for Delphi (XE and later, VCL and FMX), licensed LGPL-3.0. It's a library, not an application: no app entry point, no test suite, no build script. Code comments, docs and examples are in Portuguese.

## Dependencies (not vendored)

`Source/Dependencies/{DBCBr,DBEBr,CQLBr,JSONBr}` hold only a `readme.txt` with a download link. Nothing compiles until these four HashLoad libraries are on the Delphi library path, installed either with Boss or by hand:

```sh
boss install          # resolves boss.json deps into ./modules
```

What each dependency provides, so you know where a symbol lives:
- **DBCBr**: mapping attributes (`[Entity]`, `[Table]`, `[Column]`, `[PrimaryKey]`, `[Restrictions]`, `[Dictionary]`, associations), `TRegisterClass.RegisterEntity`, and the mapping explorer/cache (`dbcbr.mapping.*`).
- **DBEBr**: the connection abstraction `IDBConnection` / `IDBResultSet` and driver factories such as `TFactoryFireDAC.Create(Conn, dnSQLite)` (`dbebr.factory.*`). The `Components/Packages/Delphi/DBEBrConnection*.dproj.local` files belong to it.
- **CQLBr**: the fluent SQL builder used by the DML generators and `ormbr.criteria`.
- **JSONBr**: JSON serialization used by `ormbr.json` and the RESTful layer.

When a type isn't defined anywhere under `Source/`, look in these libraries.

## Building

There's no CLI build. Code compiles inside a consuming project, or through the design-time packages:
- `Projects/Wizard/ORMBrLibrary.dpk` (IDE registration in `ormbr.reg.pas`)
- `Components/Packages/Delphi/*.dpk` (REST client components, manager components, driver links)

To check that all of `Source/` compiles, build `Projects/CompileCheck/ORMBrCompileCheck.dproj` in the IDE (it points at the dependencies in the Boss cache), or run `Projects/CompileCheck/compile-check.ps1` on editions that allow command-line compiling (Community does not: `dcc32` and MSBuild both refuse). See `Projects/CompileCheck/README.md`.

To check a specific scenario, build one of the `Examples/**/*.dproj` projects that uses the unit (`msbuild X.dproj` after `rsvars.bat`), with the dependency paths configured. `Examples/Data/*` has one sample per DB access layer (FireDAC, Zeos, UniDAC, ADO, DBExpress, IBX, SQLDirect, NexusDB, ElevateDB, AbsoluteDB, SQLite native); the "Sem DataSet" variants use the ObjectSet API.

## Conditional compilation

`Source/ormbr.inc` is included by most units. It controls the framework flavor:
- `VCL` / `FMX` → `HAS_VCL` / `HAS_FMX` (VCL is on by default; on non-Windows targets `ormbr.inc` switches to FMX automatically)
- `USEFDMEMTABLE` (default) or `USECLIENTDATASET` → `USEMEMDATASET`
- `DRIVERRESTFUL`, `LOAD_DYNAMICALLY`, `MONITORRESTFULCLIENT` (off by default)
- `DELPHInn_UP` version symbols, derived from `CompilerVersion` by a cascade of `{$IF CompilerVersion >= N}` (`nn = CompilerVersion - 7`; Delphi 13 = 37 → `DELPHI30_UP`). New Delphi versions inherit every symbol automatically; you only touch this file to add a new `DELPHInn_UP` that code actually tests.

The four dependencies still use per-`VERnnn` blocks that stop at `VER360`. On Delphi 13 they compile but take legacy branches (e.g. `dbcbr.rtti.helper` without `DELPHI22_UP`, `jsonbr.builders` without `DELPHI15_UP`). Their `.inc` files need the same cascade; see Annex A of `docs/planos/2026-11-24-compatibilidade-delphi-13.md`.

## Architecture

Entities are plain classes decorated with DBCBr attributes and registered in `initialization` with `TRegisterClass.RegisterEntity(TMyEntity)`. Everything else is generic over `M: class, constructor`.

**Two front-end APIs share one core:**

1. **DataSet API** (`Source/Dataset`): binds an entity to an in-memory dataset (`TFDMemTable` / `TClientDataSet`).
   - `TContainerFDMemTable<M>` / `TContainerClientDataSet<M>` (`IContainerDataSet<M>`) for a single entity.
   - `TManagerDataSet` for master/detail trees: `AddAdapter<TDetail, TMaster>(DataSet)`, `AddLookupField`, `Open<TMaster>`.
   - Adapter chain: `TDataSetBaseAdapter<M>` → `ormbr.dataset.adapter` → `ormbr.dataset.fdmemtable` / `clientdataset`. Dataset events are hooked in `ormbr.dataset.events`. `ApplyUpdates` turns dataset changes into commands.
2. **ObjectSet API** (`Source/Objectset`): works on `TObjectList<M>` with no dataset. `TContainerObjectSet<M>` and `TManagerObjectSet` follow the same chain: `TObjectSetAbstract` → `TObjectSetBaseAdapter` → `TObjectSetAdapter`.

Both go through a **session**, `TSessionAbstract<M>` (`Core/ormbr.session.abstract.pas`), with subclasses `TSessionDataSet<M>`, `TSessionObjectSet<M>` and the RESTful `ormbr.session.restful`.

**Core pipeline** (`Source/Core`):
- `TDMLCommandFactory` (`ormbr.command.factory`) builds `ormbr.command.{selecter,inserter,updater,deleter}` commands and runs them through `ormbr.command.executor`.
- SQL text comes from a per-database **DML generator** that implements `IDMLGeneratorCommand`: the base is `ormbr.dml.generator.pas`, with one subclass per dialect (`ormbr.dml.generator.<db>.pas`). Each dialect registers itself in its `initialization` with `TDriverRegister.RegisterDriver(dnXxx, TDMLGeneratorXxx.Create)` (`ormbr.driver.register.pas`). A consuming app must put the generator unit for its database in a `uses` clause (for example `ormbr.dml.generator.sqlite`), or no generator is found at runtime. To add a database, add a generator unit with that registration.
- `ormbr.dml.cache` caches generated SQL. `ormbr.bind` moves values between result sets and objects. `ormbr.types.{nullable,blob,lazy}` define the special property types.

**Other modules:**
- `Source/Middleware`: global hooks registered through `TORMBrMiddlewares` (`ormbr.register.middleware`), covering before/after insert/update/delete events and query scopes (shared WHERE/ORDER BY). `Source/Middleware-Horse/Horse.ORMBr.pas` is a Horse integration.
- `Source/Criteria`: `ICriteria` query API with an AST and serializer.
- `Source/Livebindings`: VCL/FMX LiveBindings helpers.
- `Source/Metadata`: `ormbr.modeldb.compare` compares entity models with the database schema (DDL migration), using DBCBr metadata.
- `Source/RESTful`: a client/server split that lets the session run over HTTP instead of a DB connection.
  - `Client/`: REST drivers and factories for DataSnap, DMVC, Horse, MARS, WiRL and a generic WS.
  - `Server/`: resources for each of those frameworks, plus `restquery.parse` and Horse Swagger.
  - `Common/`: shared connection interfaces.
- `Source/Monitor`: SQL command monitor form, used with `FConn.SetCommandMonitor(TCommandMonitor.GetInstance)`.
- `Components/Source/MongoWire` with `ormbr.dml.generator.mongodb` / `nosql`: NoSQL support.

**Tooling projects** (`Projects/`): model generator from an existing DB (`Gerador Modelo`), dependency downloader (`ORMBr Dependencies`, the source of `ORMBrDependencies.exe`), installer (`ORMBr Install`, configured by `RESTFulInstall.ini`), DLL build, and the IDE wizard package.

## Conventions

- Unit names are lowercase and dotted: `ormbr.<area>.<name>.pas`. Dependency units use their own prefixes (`dbcbr.`, `dbebr.`, `cqlbr.`, `jsonbr.`).
- Every source file starts with the LGPL header block. Keep it when you create new units.
- Some files use ANSI/Latin-1 encoding (Portuguese accents in comments, as in `ormbr.inc`). Keep each file's existing encoding when you edit it.

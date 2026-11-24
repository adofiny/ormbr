# ORMBr Framework for Delphi

> **Versão modificada.** Este repositório é uma cópia do [ORMBr original (HashLoad/ormbr)](https://github.com/HashLoad/ormbr), de Isaque Pinheiro, distribuída sob a mesma licença LGPL-3.0. Alterações feitas em 24/11/2026 para compilar no **Delphi 13 Florence**:
> - `Source/ormbr.inc`: símbolos de versão calculados por `CompilerVersion` (Delphi 13 e versões futuras) e FMX automático fora do Windows.
> - `Source/Core/ormbr.types.blob.pas` e `Source/Core/ormbr.dml.generator.nosql.pas`: correções de compilação.
> - `Projects/CompileCheck/`: projeto para verificar a compilação de todo o `Source/`.
>
> Detalhes em `docs/planos/2026-11-24-compatibilidade-delphi-13.md`.

Da visão de aproveitar ao máximo o conceito de Orientação a Objetos, o Mapeamento Objeto-Relacional (ORM) consiste em um framework que tem por objetivo encurtar as distância entre a orientado a objetos e o modelo entidade-relacional, criando uma ponte (mapeamento) entre eles. Com a abordagem, é possível a construção de sistemas aplicando a orientado a objetos, cujo os objetos são persistidos em um banco de dados relacional.

Um ORM possui diversos métodos básicos que irão realizar a interação entre a aplicação e o banco de dados, se responsabilizando por algumas tarefas básicas, como o CRUD (Create, Read, Update e Delete), por exemplo. Além disso, o ORM irá gerenciar os detalhes de mapeamento de um conjunto de objetos para um banco de dados.

O ORM reduz ao mínimo a necessidade de escrever códigos de conexão e queries SQL. Dessa forma, é possível obter uma redução significativa nos códigos da aplicação, gerando um código mais elegante e consequentemente ampliando a facilidade de posteriores manutenções na aplicação.

É importante deixar claro que a utilização de um framework ORM não substitui totalmente a necessidade da utilização de SQL na sua aplicação. Embora o ORM satisfaça a maior parte das necessidades de interação com o banco de dados, em alguns casos, haverá a necessidade, por exemplo, de consultas mais customizadas, que terão que ser realizadas por meio de SQL. 
por: Bárbara Ranieri

<p align="center">
  <a href="https://www.isaquepinheiro.com.br">
    <img src="https://github.com/HashLoad/ORMBr/blob/master/Images/ormbrbitucket.png">
  </a>
</p>

## 🏛 Delphi Versions
Embarcadero Delphi XE e superior, incluindo o Delphi 13 Florence.

> **Delphi 13:** as dependências (DBCBr, DBEBr, CQLBr, JSONBr) ainda não reconhecem o Delphi 13 nos seus arquivos `.inc`. Elas compilam, mas usam ramos de código antigos. Enquanto isso não for corrigido nos repositórios delas, aplique o ajuste descrito no Anexo A de `docs/planos/2026-11-24-compatibilidade-delphi-13.md`.

## ⚙️ Instalação
Instalação usando o [`boss install`]
```sh
boss install "https://github.com/HashLoad/ormbr"
```

## ⚠ Dependências

:heavy_check_mark: [DBCBr Framework for Delphi](https://github.com/hashload/dbcbr)

:heavy_check_mark: [DBEBr Framework for Delphi/Lazarus](https://github.com/hashload/dbebr)

:heavy_check_mark: [CQLBr Framework for Delphi/Lazarus](https://github.com/hashload/cqlbr)

:heavy_check_mark: [JSONBr Framework for Delphi](https://github.com/hashload/jsonbr)

## ⚡️ Como usar
```Delphi
unit ormbr.model.client;

interface

uses
  Classes, 
  DB, 
  SysUtils, 
  Generics.Collections, 
  /// orm 
  dbcbr.mapping.attributes,
  ormbr.types.nullable,
  dbcbr.types.mapping,
  dbcbr.mapping.register,
  ormbr.types.blob;

type
  [Entity]
  [Table('client','')]
  [PrimaryKey('client_id', 'Chave primária')]
  [Indexe('idx_client_name','client_name')]
  [OrderBy('client_id Desc')]
  Tclient = class
  private
    { Private declarations }
    Fclient_id: Integer;
    Fclient_name: String;
    Fclient_foto: TBlob;
  public
    { Public declarations }
    [Restrictions([NoUpdate, NotNull])]
    [Column('client_id', ftInteger)]
    [Dictionary('client_id','Mensagem de validação','','','',taCenter)]
    property client_id: Integer read Fclient_id write Fclient_id;

    [Column('client_name', ftString, 40)]
    [Dictionary('client_name','Mensagem de validação','','','',taLeftJustify)]
    property client_name: String read Fclient_name write Fclient_name;

    [Column('client_foto', ftBlob)]
    [Dictionary('client_foto','Mensagem de validação')]
    property client_foto: TBlob read Fclient_foto write Fclient_foto;
  end;

implementation

initialization
  TRegisterClass.RegisterEntity(Tclient);

end.
```

```Delphi
unit uMainFormORM;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  DB, Grids, DBGrids, StdCtrls, Mask, DBClient, DBCtrls, ExtCtrls,

  // ORMBr
  dbebr.factory.interfaces,
  ormbr.container.dataset.interfaces,
  ormbr.container.fdmemtable,
  dbebr.factory.firedac,
  ormbr.dml.generator.sqlite,
  ormbr.model.client,

  // FireDAC, caso esteja usando ele
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.VCLUI.Wait, FireDAC.Comp.Client, FireDAC.Stan.Intf,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Comp.UI, FireDAC.DApt, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.Comp.DataSet, FireDAC.Phys.MySQL,
  FireDAC.Phys.MySQLDef, FireDAC.Phys.SQLiteWrapper.Stat;

type
  TForm3 = class(TForm)
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Button2: TButton;
    FDConnection1: TFDConnection;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDClient: TFDMemTable;
    DataSource1: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FDClientAfterInsert(DataSet: TDataSet);
  private
    { Private declarations }
    // Interface de conexão do ORMBr
    FConn: IDBConnection;
    // Interface para acontrolar o DataSet
    FContainerClient: IContainerDataSet<Tclient>;
public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

uses
  StrUtils;

{$R *.dfm}

procedure TForm3.Button2Click(Sender: TObject);
begin
  FContainerClient.ApplyUpdates(0);
end;

procedure TForm3.FDClientAfterInsert(DataSet: TDataSet);
var
  ID: TGUID;
begin
  FDClient.FieldByName('client_id').AsString := GUIDToString(ID);
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  // Instância da class de conexão via FireDAC
  FConn := TFactoryFireDAC.Create(FDConnection1, dnSQLite);
  // Client
  FContainerClient := TContainerFDMemTable<Tclient>.Create(oConn, FDClient);

  FContainerClient.Open;
end;

end.
```

```Delphi
...

procedure TForm3.FormCreate(Sender: TObject);
begin
  // Instância da class de conexão via FireDAC
  FConn := TFactoryFireDAC.Create(FDConnection1, dnMySQL);

  FManager := TManagerDataSet.Create(oConn);
  FConn.SetCommandMonitor(TCommandMonitor.GetInstance);
  FManager.AddAdapter<Tmaster>(FDMaster, 3)
          .AddAdapter<Tdetail, Tmaster>(FDDetail)
          .AddAdapter<Tclient, Tmaster>(FDClient)
          .AddAdapter<Tlookup>(FDLookup)
          .AddLookupField<Tdetail, Tlookup>('fieldname',
                                            'lookup_id',
                                            'lookup_id',
                                            'lookup_description',
                                            'Descrição Lookup');
  FManager.Open<Tmaster>;
end;
```

## ✍️ License
[![License](https://img.shields.io/badge/Licence-LGPL--3.0-blue.svg)](https://opensource.org/licenses/LGPL-3.0)

## ⛏️ Contribuição

Nossa equipe adoraria receber contribuições para este projeto open source. Se você tiver alguma ideia ou correção de bug, sinta-se à vontade para abrir uma issue ou enviar uma pull request.

[![Issues](https://img.shields.io/badge/Issues-channel-orange)](https://github.com/HashLoad/ormbr/issues)

Para enviar uma pull request, siga estas etapas:

1. Faça um fork do projeto
2. Crie uma nova branch (`git checkout -b minha-nova-funcionalidade`)
3. Faça suas alterações e commit (`git commit -am 'Adicionando nova funcionalidade'`)
4. Faça push da branch (`git push origin minha-nova-funcionalidade`)
5. Abra uma pull request

## 📬 Contato
[![Telegram](https://img.shields.io/badge/Telegram-channel-blue)](https://t.me/hashload)

## 💲 Doação
[![Doação](https://img.shields.io/badge/PagSeguro-contribua-green)](https://pag.ae/bglQrWD)

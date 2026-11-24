{
      ORM Brasil é um ORM simples e descomplicado para quem utiliza Delphi

                   Copyright (c) 2016, Isaque Pinheiro
                          All rights reserved.

                    GNU Lesser General Public License
                      Versão 3, 29 de junho de 2007

       Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
       A todos é permitido copiar e distribuir cópias deste documento de
       licença, mas mudá-lo não é permitido.

       Esta versão da GNU Lesser General Public License incorpora
       os termos e condições da versão 3 da GNU General Public License
       Licença, complementado pelas permissões adicionais listadas no
       arquivo LICENSE na pasta principal.
}

{ @abstract(ORMBr Framework - verificação de compilação.)
  @abstract(Programa sem lógica: existe só para compilar todas as units de
            Source/ de uma vez, em qualquer versão do Delphi e plataforma.
            Use o script compile-check.ps1 desta pasta.)
}

{
  Units de Source/ que NÃO entram neste check, porque dependem de frameworks
  de terceiros que não fazem parte do ORMBr nem das suas dependências:

    Horse ............ Middleware-Horse/Horse.ORMBr.pas
                       RESTful/Client/ormbr.client.restdriver.horse.pas
                       RESTful/Client/ormbr.client.resthorse.factory.pas
                       RESTful/Server/ormbr.server.horse.pas
                       RESTful/Server/ormbr.server.resource.horse.pas
                       RESTful/Server/ormbr.server.swagger.horse.pas (GBSwagger)
    Delphi MVC ....... RESTful/Client/ormbr.client.dmvc.pas
                       RESTful/Client/ormbr.client.restdriver.dmvc.pas
                       RESTful/Client/ormbr.client.restdmvc.factory.pas
                       RESTful/Server/ormbr.server.dmvc.pas
                       RESTful/Server/ormbr.server.resource.dmvc.pas
    MARS ............. RESTful/Client/ormbr.client.mars.pas
                       RESTful/Client/ormbr.client.restdriver.mars.pas
                       RESTful/Client/ormbr.client.restmars.factory.pas
                       RESTful/Server/ormbr.server.mars.pas
                       RESTful/Server/ormbr.server.resource.mars.pas
    WiRL ............. RESTful/Client/ormbr.client.wirl.pas
                       RESTful/Client/ormbr.client.restdriver.wirl.pas
                       RESTful/Client/ormbr.client.restwirl.factory.pas
                       RESTful/Server/ormbr.server.wirl.pas
                       RESTful/Server/ormbr.server.resource.wirl.pas
    DataSnap ......... RESTful/Client/ormbr.client.datasnap.pas
                       RESTful/Client/ormbr.client.restdriver.datasnap.pas
                       RESTful/Client/ormbr.client.restdatasnap.factory.pas
                       RESTful/Server/ormbr.server.datasnap.pas
                       RESTful/Server/ormbr.server.resource.datasnap.pas
}

program ORMBrCompileCheck;

{$APPTYPE CONSOLE}

uses
  // Core
  ormbr.bind,
  ormbr.command.abstract,
  ormbr.command.deleter,
  ormbr.command.executor.abstract,
  ormbr.command.executor,
  ormbr.command.factory,
  ormbr.command.inserter,
  ormbr.command.selecter,
  ormbr.command.updater,
  ormbr.core.consts,
  ormbr.dml.cache,
  ormbr.dml.commands,
  ormbr.dml.generator,
  ormbr.dml.generator.absolutedb,
  ormbr.dml.generator.ads,
  ormbr.dml.generator.elevatedb,
  ormbr.dml.generator.firebird,
  ormbr.dml.generator.firebird3,
  ormbr.dml.generator.interbase,
  ormbr.dml.generator.mongodb,
  ormbr.dml.generator.mssql,
  ormbr.dml.generator.mysql,
  ormbr.dml.generator.nexusdb,
  ormbr.dml.generator.nosql,
  ormbr.dml.generator.oracle,
  ormbr.dml.generator.postgresql,
  ormbr.dml.generator.sqlite,
  ormbr.dml.interfaces,
  ormbr.driver.register,
  ormbr.json,
  ormbr.objects.helper,
  ormbr.objects.utils,
  ormbr.rtti.helper,
  ormbr.session.abstract,
  ormbr.types.blob,
  ormbr.types.lazy,
  ormbr.types.nullable,
  ormbr.utils,
  // Criteria
  ormbr.criteria,
  ormbr.criteria.ast,
  ormbr.criteria.resultset,
  ormbr.criteria.serialize,
  // Dataset
  ormbr.container.clientdataset,
  ormbr.container.dataset,
  ormbr.container.dataset.interfaces,
  ormbr.container.fdmemtable,
  ormbr.dataset.abstract,
  ormbr.dataset.adapter,
  ormbr.dataset.base.adapter,
  ormbr.dataset.clientdataset,
  ormbr.dataset.consts,
  ormbr.dataset.events,
  ormbr.dataset.fdmemtable,
  ormbr.dataset.fields,
  ormbr.manager.dataset,
  ormbr.session.dataset,
  // Objectset
  ormbr.container.objectset,
  ormbr.container.objectset.interfaces,
  ormbr.manager.objectset,
  ormbr.objectset.abstract,
  ormbr.objectset.adapter,
  ormbr.objectset.base.adapter,
  ormbr.session.objectset,
  // Middleware
  ormbr.after.delete.middleware,
  ormbr.after.insert.middleware,
  ormbr.after.update.middleware,
  ormbr.before.delete.middleware,
  ormbr.before.insert.middleware,
  ormbr.before.update.middleware,
  ormbr.events.middleware,
  ormbr.query.scope.middleware,
  ormbr.register.middleware,
  // Metadata
  ormbr.metadata.classe.factory,
  ormbr.modeldb.compare,
  // Livebindings
  ormbr.controls.helpers,
  ormbr.fmx.controls,
  ormbr.onetomany,
  // RESTful - Common
  ormbr.restcomponent,
  ormbr.restfactory.connection,
  ormbr.restfactory.interfaces,
  // RESTful - Client (somente RTL)
  ormbr.client,
  ormbr.client.base,
  ormbr.client.consts,
  ormbr.client.horse,
  ormbr.client.methods,
  ormbr.client.restdriver,
  ormbr.client.restdriver.ws,
  ormbr.client.restexception,
  ormbr.client.restws.factory,
  ormbr.client.ws,
  ormbr.restdataset.adapter,
  ormbr.restdataset.clientdataset,
  ormbr.restdataset.fdmemtable,
  ormbr.restobjectset.adapter,
  ormbr.session.restful,
  // RESTful - Server (somente RTL)
  ormbr.server.resource,
  ormbr.server.restobject.manager,
  ormbr.server.restobjectset,
  ormbr.server.restobjectset.session,
  ormbr.server.restquery.parse
  {$IFDEF MSWINDOWS}
  // Somente Windows
  , ormbr.form.monitor
  , ormbr.livebindings
  , ormbr.vcl.controls
  , SQLite3
  , SQLiteTable3
  {$ENDIF}
  ;

begin
end.

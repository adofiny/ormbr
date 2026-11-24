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

{ 
  @abstract(ORMBr Framework.)
  @created(20 Jul 2016)
  @author(Isaque Pinheiro <isaquepsp@gmail.com>)
  @author(Skype : ispinheiro)
}

{
  Windows MSWINDOWS
  macOS MACOS
  iOS IOS
  Android ANDROID
  Linux LINUX
}

{
  Compiler			CompilerVersion		Defined Symbol	Used BPL
  Delphi 13 Florence    	37 			VER370		37
  Delphi 12.? ??         	36 			VER360		29
  Delphi 11.1 Alexandria 	35 			VER350		28
  Delphi 10.4 Sidney     	34 			VER340		27
  Delphi 10.3 Rio		33 			VER330		26
  Delphi 10.2 Tokyo	 	32 			VER320		25
  Delphi 10.1 Berlin	 	31			VER310		24
  Delphi 10 Seattle	 	30			VER300          23
  Delphi XE8		 	29 			VER290          22
  Delphi XE7		 	28 			VER280          21
  Delphi XE6		 	27 			VER270          20
  Delphi XE5		 	26 			VER260          19
  Delphi XE4		 	25 			VER250          18 
  Delphi XE3		 	24 			VER240          17
  Delphi XE2		 	23 			VER230          16
  Delphi XE	        	22 			VER220          15
  Delphi 2010 	       		21 			VER210          14
}

{$DEFINE VCL}
{.$DEFINE FMX}
{.$DEFINE LOAD_DYNAMICALLY}
{.$DEFINE DRIVERRESTFUL}
{$DEFINE USEFDMEMTABLE}
{.$DEFINE USECLIENTDATASET}
{.$DEFINE MONITORRESTFULCLIENT}

// Fora do Windows nao existe VCL: usa FMX automaticamente.
{$IFNDEF MSWINDOWS}
  {$UNDEF VCL}
  {$DEFINE FMX}
{$ENDIF}

{$IFDEF FMX}
  {$DEFINE HAS_FMX}
{$ENDIF}
{$IFDEF VCL}
  {$DEFINE HAS_VCL}
{$ENDIF}

{$IFDEF USEFDMEMTABLE}
  {$DEFINE USEMEMDATASET}
{$ENDIF}

{$IFDEF USECLIENTDATASET}
  {$DEFINE USEMEMDATASET}
{$ENDIF}

// Simbolos DELPHInn_UP a partir de CompilerVersion (nn = CompilerVersion - 7).
// Cada versao define tambem os simbolos de todas as anteriores, entao versoes
// novas do Delphi herdam tudo sem precisar editar este arquivo.
{$IFNDEF FPC}
  {$IF CompilerVersion >= 21.0} {$DEFINE DELPHI14_UP} {$IFEND} // Delphi 2010
  {$IF CompilerVersion >= 22.0} {$DEFINE DELPHI15_UP} {$IFEND} // Delphi XE
  {$IF CompilerVersion >= 23.0} {$DEFINE DELPHI16_UP} {$IFEND} // Delphi XE2
  {$IF CompilerVersion >= 24.0} {$DEFINE DELPHI17_UP} {$IFEND} // Delphi XE3
  {$IF CompilerVersion >= 25.0} {$DEFINE DELPHI18_UP} {$IFEND} // Delphi XE4
  {$IF CompilerVersion >= 26.0} {$DEFINE DELPHI19_UP} {$IFEND} // Delphi XE5
  {$IF CompilerVersion >= 27.0} {$DEFINE DELPHI20_UP} {$IFEND} // Delphi XE6
  {$IF CompilerVersion >= 28.0} {$DEFINE DELPHI21_UP} {$IFEND} // Delphi XE7
  {$IF CompilerVersion >= 29.0} {$DEFINE DELPHI22_UP} {$IFEND} // Delphi XE8
  {$IF CompilerVersion >= 30.0} {$DEFINE DELPHI23_UP} {$IFEND} // Delphi 10 Seattle
  {$IF CompilerVersion >= 31.0} {$DEFINE DELPHI24_UP} {$IFEND} // Delphi 10.1 Berlin
  {$IF CompilerVersion >= 32.0} {$DEFINE DELPHI25_UP} {$IFEND} // Delphi 10.2 Tokyo
  {$IF CompilerVersion >= 33.0} {$DEFINE DELPHI26_UP} {$IFEND} // Delphi 10.3 Rio
  {$IF CompilerVersion >= 34.0} {$DEFINE DELPHI27_UP} {$IFEND} // Delphi 10.4 Sydney
  {$IF CompilerVersion >= 35.0} {$DEFINE DELPHI28_UP} {$IFEND} // Delphi 11 Alexandria
  {$IF CompilerVersion >= 36.0} {$DEFINE DELPHI29_UP} {$IFEND} // Delphi 12 Athens
  {$IF CompilerVersion >= 37.0} {$DEFINE DELPHI30_UP} {$IFEND} // Delphi 13 Florence
{$ENDIF}

//Lazarus
{$IFDEF FCP}
  {$DEFINE DELPHI14_UP}
{$ENDIF}

{$IFDEF DELPHI15_UP}
  {$DEFINE FORMATSETTINGS}
{$ENDIF}

{$IFDEF DELPHI17_UP}
  {$DEFINE HAS_NET_ENCODING}
{$ELSE IFDEF DELPHI16_UP}
  {$DEFINE HAS_SOAP_ENCODING}
{$ELSE}
  {$DEFINE HAS_ENCDDECD}
{$ENDIF}

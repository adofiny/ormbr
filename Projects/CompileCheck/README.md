# CompileCheck — verificação de compilação do ORMBr

Programa sem lógica que lista nos `uses` todas as units de `Source/` que dependem só da RTL e das quatro dependências (DBCBr, DBEBr, CQLBr, JSONBr). Se ele compila, o `Source/` compila naquela versão do Delphi e plataforma.

As units que dependem de Horse, Delphi MVC, MARS, WiRL ou DataSnap ficam fora; a lista está no cabeçalho de `ORMBrCompileCheck.dpr`.

## Dependências

O `.dproj` procura as dependências no cache do Boss (`%USERPROFILE%\.boss\cache\<hash>_wt\Source`), as versões referenciadas pelo `boss.json`. Para usar outra cópia:

- defina a variável de ambiente `ORMBrDepsRoot` (na IDE: *Tools > Options > IDE > Environment Variables*) apontando para a pasta que contém as quatro, com os mesmos nomes de subpasta; ou
- edite as propriedades `ORMBrDBCBr`, `ORMBrDBEBr`, `ORMBrCQLBr` e `ORMBrJSONBr` no `.dproj`.

## Pela IDE (qualquer edição)

1. Abra `ORMBrCompileCheck.dproj`.
2. Escolha a plataforma (Win32 ou Win64) e use *Project > Build ORMBrCompileCheck*.
3. Os erros e avisos aparecem no painel *Messages*. Saída em `dcu\<versão>\<plataforma>\`.

## Por linha de comando (Professional ou superior)

A edição Community não compila por linha de comando; nela o script sai com código 2.

```powershell
.\compile-check.ps1 -Delphi 37.0 -Platform Win32 -DepsRoots 'C:\...\dbcbr\Source','C:\...\dbebr\Source','C:\...\cqlbr\Source','C:\...\jsonbr\Source'
```

`-Platform` aceita `Win32`, `Win64`, `Android64` e `iOSDevice64`. Nas duas últimas o script compila só até `.dcu` (sem link), então não precisa de SDK configurado. Código de saída: 0 sem erros, 1 erro de compilação, 2 erro de configuração.

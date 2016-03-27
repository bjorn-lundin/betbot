unit sql;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, pqconnection,sqldb;
  //dialogs;

function CreateConnection: TPQConnection;
function CreateTransaction(pConnection: TPQConnection): TSQLTransaction;
function CreateQuery(pTransaction: TSQLTransaction): TSQLQuery;

implementation

function CreateConnection: TPQConnection;
begin
  result := TPQConnection.Create(nil);
  result.Hostname := 'db.nonodev.com';
  result.DatabaseName := 'bnl';
  result.UserName := 'bnl';
  result.Password := 'ld4BC9Q51FU9CYjC21gp';
//  result.Hostname := '192.168.1.20';
//  result.DatabaseName := 'ghd';
//  result.UserName := 'bnl';
//  result.Password := 'bnl';
end;


function CreateTransaction(pConnection: TPQConnection): TSQLTransaction;
begin
  result := TSQLTransaction.Create(pConnection);
  result.Database := pConnection;
end;


function CreateQuery(pTransaction: TSQLTransaction): TSQLQuery;
begin
  result := TSQLQuery.Create(pTransaction.Database);
  result.Database := pTransaction.Database;
  result.Transaction := pTransaction
end;


end.



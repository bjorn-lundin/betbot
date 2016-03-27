program todays_profit;

uses SDL2, SDL2_ttf, Progressbar, rendered_text,sysutils,
  sql, pqconnection,sqldb,math,db;

var
PQConn : TPQConnection;
T : TSQLTransaction;
Get_Exposed, Get_Profit : TSQLQuery;

sdlWindow : PSDL_Window;
sdlRenderer : PSDL_Renderer;
RT_Profit     : TRendered_text;
RT_In_The_Air : TRendered_text;
Pb : TProgressBar;
i : integer;

sdlEvent: PSDL_Event;
Do_Continue : Boolean = True;
In_The_Air  : Double = 0.0;
The_Profit  : Double = 0.0;

procedure Init;
  //--------------------
  procedure Log_And_Halt(S : string);
  begin
    Writeln(S);
    Writeln(SDL_GetError);
    Halt;
  end;
  //--------------------
begin
  //initilization of video subsystem
  if SDL_Init(SDL_INIT_VIDEO) < 0 then Log_And_Halt('SDL_Init');

  sdlWindow := SDL_CreateWindow('Today''s profit', 50, 50, 240, 240, SDL_WINDOW_SHOWN);
  if sdlWindow = nil then Log_And_Halt('SDL_CreateWindow');

  sdlRenderer := SDL_CreateRenderer(sdlWindow, -1, SDL_RENDERER_ACCELERATED);
  if sdlRenderer = nil then Log_And_Halt('SDL_CreateRenderer');

  //initialization of TrueType font engine and loading of a font
  if TTF_Init = -1 then Log_And_Halt('TTF_Init');   ;

  PQConn := Sql.CreateConnection;
  T := Sql.CreateTransaction(PQConn);
  Get_Exposed := Sql.CreateQuery(T);
  Get_Profit := Sql.CreateQuery(T);

  new(sdlEvent);
end;


procedure Quit;
begin
  Pb.Destroy;
  RT_Profit.Destroy;
  RT_In_The_Air.Destroy;
  Get_Exposed.Free;
  Get_Profit.Free;
  T.Free;
  PQConn.Close;
  PQConn.Free;
  dispose(sdlEvent);
  TTF_Quit;
  SDL_DestroyRenderer( sdlRenderer );
  SDL_DestroyWindow ( sdlWindow );
  SDL_Quit;
end;



function Exposed : Double;
var
  sSql : String;
begin
  Result := 0.0;
  sSql := 'select ';
  sSql += ' case B.SIDE ';
  sSql += '  when ''LAY''  then sum(B.SIZE) * (avg(PRICE)-1) ';
  sSql += '  when ''BACK'' then sum(B.SIZE) ';
  sSql += '  else 0.0 ';
  sSql += ' end as exposed ';
  sSql += 'from ABETS B ';
  sSql += 'where B.BETWON is NULL ';
  sSql += 'and B.EXESTATUS = ''SUCCESS'' ';
  sSql += 'and B.BETPLACED::date = (select current_date) ';
  sSql += 'group by B.SIDE ';
  writeln(sSql);
  
  Get_Exposed.SQL.Text := sSql;
  T.StartTransaction;
  Get_Exposed.Prepare;
  Get_Exposed.Open;
  if not Get_Exposed.Eof then Result := Get_Exposed.FieldByName('exposed').AsFloat;
  Get_Exposed.Close;
  T.Commit;
end;

function Profit : Double;
var
  sSql : String;
begin
  Result := 0.0;
  sSql := 'select sum(B.PROFIT) as sm ';
  sSql += 'from ABETS B ';
  sSql += 'where B.BETWON is not NULL ';
  sSql += 'and B.STATUS = ''SETTLED'' ';
  sSql += 'and B.EXESTATUS = ''SUCCESS'' ';
  sSql += 'and B.BETPLACED::date = (select current_date) ';
  Get_Profit.SQL.Text := sSql;
  T.StartTransaction;
  Get_Profit.Prepare;
  Get_Profit.Open;
  if not Get_Profit.Eof then Result := Get_Profit.FieldByName('sm').AsFloat;
  Get_Profit.Close;
  T.Commit;
end;


procedure Do_It;
begin
  SDL_SetRenderDrawColor( sdlRenderer, 0, 0, 0, 0 );
  SDL_RenderClear( sdlRenderer );
  writeln('1');
  In_The_Air := Exposed;
  writeln('2');
  The_Profit := Profit;
  writeln('3');
  writeln('ith', In_The_Air);
  writeln('pr', The_Profit);
  
  
  RT_Profit.Update(IntToStr(round(The_Profit)));
  RT_In_The_Air.Update('In the air: ' + IntToStr(round(In_The_Air)));
end;

//----------------------------------------
begin
  Init;
  Pb := TProgressBar.Create(20,220,200,10, sdlRenderer);
  RT_In_The_Air := TRendered_Text.Create(10,10,150,40,255,0,0, sdlRenderer);
  RT_Profit := TRendered_Text.Create(30,60,180,120,255,255,255, sdlRenderer);
  Do_It;
  i := 0;
  while Do_Continue do begin
    while SDL_PollEvent( sdlEvent ) = 1 do begin
      //Writeln( 'Event detected: ' );
      case sdlEvent^.type_ of
        //keyboard events
        SDL_KEYDOWN:     begin
                           case sdlEvent^.key.keysym.sym of
                             SDLK_ESCAPE: Do_Continue := False;  // exit on pressing ESC key
                           end;
                         end;
        //window events
        SDL_WINDOWEVENT: begin
                           //write( 'Window event: ' );
                           case sdlEvent^.window.event of
                             SDL_WINDOWEVENT_CLOSE: Do_Continue := False;
                           end;
                         end;
      end;
    end;
    i := i+1;
    Pb.Update(i/60.0);
    if (i = 60) and Do_Continue then begin // don't delay the exit
      Do_It;
      i := 0;
    end;
    if Do_Continue then SDL_Delay(1000); // don't delay the exit
  end;
  Quit;
end.


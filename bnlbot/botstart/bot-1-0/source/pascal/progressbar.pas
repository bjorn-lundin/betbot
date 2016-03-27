unit Progressbar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SDL2;

type TProgressBar = class
  left,top,height,width : integer;
  Renderer : PSDL_Renderer ;
public
  constructor Create(l,t,w,h : integer; R : PSDL_Renderer);
  procedure Update(Progress : double);
end;



implementation

constructor TProgressBar.Create(l,t,w,h : integer;R : PSDL_Renderer);
begin
  Self.Left := l;
  Self.Top := t;
  Self.Height := h;
  Self.Width := w;
  Self.Renderer := R;
end;


procedure TProgressBar.Update(Progress : double);
var
  Rect : PSDL_Rect;
begin
  new(Rect);
  Rect^.x := Self.Left;
  Rect^.y := Self.Top;
  Rect^.w := Self.Width;
  Rect^.h := Self.Height;

  SDL_SetRenderDrawColor( Self.Renderer, 255, 255, 255, 255 );
  SDL_RenderDrawRect( Self.Renderer, Rect );

  Rect^.w := Round(Self.Width * Progress);
  SDL_RenderDrawRect( Self.Renderer, Rect );
  SDL_RenderFillRect( Self.Renderer, Rect );

  SDL_RenderPresent ( Self.Renderer );
  dispose( Rect );

end;

end.


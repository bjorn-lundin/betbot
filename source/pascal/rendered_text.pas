unit Rendered_Text;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,SDL2,SDL2_ttf;


type TRendered_Text = class
  left,top,height,width : integer;
  Red,Green,Blue : Uint8;
  Renderer : PSDL_Renderer ;

private


public
  constructor Create(l,t,w,h : integer;
                     r,g,b : Uint8;
                     Rend : PSDL_Renderer);
  procedure Update(Text : String);
end;



implementation


constructor TRendered_Text.Create(l,t,w,h : integer;
                                  r,g,b : Uint8;
                                  Rend : PSDL_Renderer);
begin
  Self.Left := l;
  Self.Top := t;
  Self.Height := h;
  Self.Width := w;
  Self.Red := r;
  Self.Green := g;
  Self.Blue := b;
  Self.Renderer := Rend;
end;



procedure TRendered_Text.Update(Text : String);
var
  pRect  : PSDL_Rect;
  pColor : PSDL_Color;
  pFont  : PTTF_Font;
  pText  : PAnsiChar;
  pSurface : PSDL_Surface;
  pTexture : PSDL_Texture;
begin

  new(pColor);
  pColor^.r := Self.Red;
  pColor^.g := Self.Green;
  pColor^.b := Self.Blue;

  new(pRect);
  pRect^.x := Self.Left;
  pRect^.y := Self.Top;
  pRect^.w := Self.Width;
  pRect^.h := Self.Height;

  new(pText);
  pText := PAnsiChar(AnsiString(Text));


  pFont := TTF_OpenFont( 'C:\WINDOWS\fonts\Arial.ttf', 200 );
  TTF_SetFontStyle(pFont, TTF_STYLE_NORMAL);

 //TTF_SetFontOutline(pFont, 1);
  TTF_SetFontHinting(pFont, TTF_HINTING_NORMAL);

  SDL_RenderSetViewport( Self.Renderer, pRect );
  pSurface := TTF_RenderText_Blended(pFont, pText, pColor^);

  pTexture := SDL_CreateTextureFromSurface(Self.Renderer, pSurface);

  //rendering of the texture
  SDL_RenderCopy(Self.Renderer, pTexture, nil, nil);

  SDL_RenderPresent (Self.Renderer);
  SDL_RenderSetViewport( Self.Renderer, nil);

  SDL_FreeSurface(pSurface);
  SDL_DestroyTexture(pTexture);

  TTF_CloseFont(pFont);
  dispose(pRect);
  dispose(pColor);
  //dispose(pText);

end;


end.


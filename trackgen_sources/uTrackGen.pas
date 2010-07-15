unit uTrackGen;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtDlgs, StdCtrls, Math;

type
  TForm1 = class(TForm)
    dlg: TOpenPictureDialog;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormShow(Sender: TObject);
var
 B: TBitmap;
 i, j, n: integer;
 s: string;
 ss: TStrings;
begin
 if dlg.Execute(self.Handle) then
  begin
    s := copy( ExtractFileName(dlg.FileName), 0, length(ExtractFileName(dlg.FileName)) - 4) + '="';


    B:= TBitmap.Create;
    B.LoadFromFile(dlg.FileName);

    for I := 0 to b.Width - 1 do
     begin
       n := 0;
       for J := 0 to b.Height - 1 do
         if b.Canvas.Pixels[i, j] <> clWhite then
           n := n + trunc(power(2, j));

       s := s + IntToHex(n, 3);
     end;

     s := s + '"';
     ss := TStringList.Create;
     ss.Add(s);
     ss.Add('size=' + IntToStr(b.Width));
     ss.SaveToFile(ChangeFileExt(dlg.FileName, '.lua'));
     ss.Free;
     B.Free;
     ShowMessage( 'DONE' );
  end;

  close;
end;

end.

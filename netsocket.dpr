program netsocket;

uses
  System.StartUpCopy,
  FMX.Forms,
  Form.AppMain in 'Form.AppMain.pas' {Form12},
  Net.HTTPSocket in 'Net.HTTPSocket.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm12, Form12);
  Application.Run;
end.

unit Net.Socket;

interface

uses
  System.Types,
  System.SysUtils,
  System.Classes,
  System.Threading,
  System.Net.Socket;

type

  TReceivedEvent = procedure (Sender: TObject; const Bytes: TBytes) of object;

  TTCPSocket = class(TSocket)
  private
    FOnConnect: TNotifyEvent;
    FOnClose: TNotifyEvent;
    FOnReceived: TReceivedEvent;
    FOnExcept: TNotifyEvent;
    FException: Exception;
  protected
    ReceivedBytes: TBytes;
    function Connected: Boolean;
    procedure DoConnect; override;
    procedure DoAfterConnect; virtual;
    procedure DoReceived; virtual;
    procedure DoClose; virtual;
    procedure DoExcept(E: Exception); virtual;
  public
    constructor Create; virtual;
    procedure ConnectTo(const Address: string; Port: Word);
    procedure Disconnect;
    property E: Exception read FException;
    property OnConnect: TNotifyEvent read FOnConnect write FOnConnect;
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
    property OnReceived: TReceivedEvent read FOnReceived write FOnReceived;
    property OnExcept: TNotifyEvent read FOnExcept write FOnExcept;
  end;

implementation

// https://docs.microsoft.com/ru-ru/dotnet/framework/network-programming/asynchronous-client-socket-example?view=netframework-4.8

constructor TTCPSocket.Create;
begin
  inherited Create(TSocketType.TCP);
end;

procedure TTCPSocket.Disconnect;
begin
  if Connected then Close;
end;

function TTCPSocket.Connected: Boolean;
begin
  Result:=TSocketState.Connected in State;
end;

procedure TTCPSocket.ConnectTo(const Address: string; Port: Word);
begin

  TTask.Run(

  procedure
  begin

    try

      Connect(TNetEndpoint.Create(TIPAddress.Create(Address),Port));

    except on E: Exception do

      DoExcept(E);

    end;

  end);

end;

procedure TTCPSocket.DoConnect;
begin

  TTask.Run(

  procedure
  begin

    try

      inherited;

      DoAfterConnect;

      TTask.Run(

      procedure
      begin

        while Connected and (WaitForData=wrSignaled) do

        try

          TThread.Synchronize(nil,

          procedure
          begin

            DoReceived;

          end);

          if Length(ReceivedBytes)=0 then Break;

        except on E: Exception do

          DoExcept(E);

        end;

        DoClose;

      end);

    except on E: Exception do

      DoExcept(E);

    end;

  end);

end;

procedure TTCPSocket.DoAfterConnect;
begin

  if Assigned(FOnConnect) then

  TThread.Synchronize(nil,

  procedure
  begin

    FOnConnect(Self);

  end);

end;

procedure TTCPSocket.DoReceived;
begin

  Receive(ReceivedBytes);

  if Assigned(FOnReceived) then FOnReceived(Self,ReceivedBytes);

end;

procedure TTCPSocket.DoClose;
begin

  TThread.Synchronize(nil,

  procedure
  begin

    Disconnect;

    if Assigned(FOnClose) then FOnClose(Self);

  end);

end;

procedure TTCPSocket.DoExcept(E: Exception);
begin

  if Assigned(FOnExcept) then

  TThread.Synchronize(nil,

  procedure
  begin
    FException:=E;
    FOnExcept(Self);
    FException:=nil;
  end)

  else raise E;

end;

end.

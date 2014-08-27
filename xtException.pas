unit xtException; 

interface 

uses 
  SysUtils; 

type
  PErrorDetails = ^TErrorDetails;                  //---------------------------------- 
  TErrorDetails = record                           //                                 |   Error Detail record. 
    sUnit: string;                                 //                                 |-> Can be changed by the implementor 
    sModule: string;                               //                                 |   To suit his requirement 
    sMethod: string;                               //                                 | 
  end;                                             //---------------------------------- 
  TCallStack = array of PErrorDetails;                                                 // <- Array of Pointer 

type 
  ECustomException = class(Exception) 
  private 
    FCallStack: TCallStack; 
    function GetStackLength: integer; 
    function GetErrorDetails(Index: integer): TErrorDetails; 
  protected 
  public 
    constructor Create(AMessage: string; AErrorDetails: TErrorDetails); overload; 
    constructor Create(AMessage: string; AException: ECustomException); overload; 
    destructor Destroy; override; 

    procedure AddToCallStack(AErrorDetails: TErrorDetails); 
    property StackLength: integer read GetStackLength; 
    property ErrorDetails[Index: integer]: TErrorDetails read GetErrorDetails; default; 
  end; 

implementation 

{ ECustomException } 

constructor ECustomException.Create(AMessage: string; 
  AErrorDetails: TErrorDetails); 
begin 
  inherited Create(AMessage); 
  AddToCallStack(AErrorDetails); 
end; 

procedure ECustomException.AddToCallStack(AErrorDetails: TErrorDetails); 
var 
  ptrErrDet: PErrorDetails; 
begin 
  New(ptrErrDet); 
  ptrErrDet^ := AErrorDetails; 
  SetLength(FCallStack, High(FCallStack) + 2); 
  FCallStack[High(FCallStack)] := ptrErrDet; 
end; 

constructor ECustomException.Create(AMessage: string; 
  AException: ECustomException); 
var 
  iCount: integer; 
begin 
  inherited Create(AMessage); 

  for iCount := Low(AException.FCallStack) to High(AException.FCallStack) do 
    AddToCallStack(AException.FCallStack[iCount]^); 
end; 

destructor ECustomException.Destroy; 
var 
  iCount: integer; 
begin 
  inherited; 
  for iCount := Low(FCallStack) to High(FCallStack) do 
    Dispose(FCallStack[iCount]); 

  if Assigned(FCallStack) then 
    Finalize(FCallStack); 
end; 

function ECustomException.GetStackLength: integer; 
begin 
  Result := High(FCallStack); 
end; 

function ECustomException.GetErrorDetails(Index: integer): TErrorDetails; 
begin 
  if (Index > -1) and (Index < StackLength) then 
    Result := FCallStack[Index]^; 
end; 

end.

unit UtilesVelox;

interface

uses
  Androidapi.JNI.Location, System.Sensors, System.Sensors.Components,
  System.Types, FMX.Objects, FMX.Forms, UTM_WGS84;

type
  TPosicion = record
    X,Y: Single;
    CG: TLocationCoord2D;
  end;

  TRegistro = record
    PosInicial,
    PosFinal,
    PosAnterior,
    PosActual: TPosicion;
    Rumbo: string;
    DistRecorrida,
    Velocidad,
    VelMaxima,
    Altitud,
    Tiempo: single;
    TiempoInicio,
    TiempoFin,
    TiempoAnterior,
    TiempoActual: TTime;
    EstaIniciando: boolean;
    AzimutActual: Double;
  end;

const
  FactorKmh=3.5999999999971;

var
  Reg: TRegistro;

  procedure ActivarGPS(LcSensor: TLocationSensor; Activo: boolean);
  procedure CargarCoordenadas(CoordGPS: TLocationCoord2D; var CoordPos: TPosicion);
  function CalcularDistancia(X1,Y1,X2,Y2: double): double;
  function Orientacion(Grados: double): string;
  function MetrosToKm(DistMetros: single): single;
  function SegundosToHoras(TmpSegs: single): single;
  procedure RotarFlecha(Imagen: TCircle; Azimut: Double; var Azmt: Double);

implementation

uses
  System.Permissions, FMX.DialogService;

/// Utilidades de la app: ///

procedure ActivarGPS(LcSensor: TLocationSensor; Activo: boolean);
const
  PermissionAccessFineLocation='android.permission.ACCESS_FINE_LOCATION';
begin
  PermissionsService.RequestPermissions([PermissionAccessFineLocation],
    procedure(const APermissions: TClassicStringDynArray;
              const AGrantResults: TClassicPermissionStatusDynArray)
    begin
      if (Length(AGrantResults)=1) and (AGrantResults[0]=TPermissionStatus.Granted) then
        LcSensor.Active:=Activo
      else
      begin
        Activo:=false;
        TDialogService.ShowMessage('Acceso a Localización no concedido');
      end;
    end);
end;

procedure CargarCoordenadas(CoordGPS: TLocationCoord2D; var CoordPos: TPosicion);
var
  LatLon: TRecLatLon;
  UTM: TRecUTM;
begin
  LatLon.Lat:=CoordGPS.Latitude;
  LatLon.Lon:=CoordGPS.Longitude;
  LatLon_To_UTM(LatLon,UTM);
  CoordPos.CG:=CoordGPS;
  CoordPos.X:=UTM.X;
  CoordPos.Y:=UTM.Y;
end;

function CalcularDistancia(X1,Y1,X2,Y2: double): double;
begin
  Result:=Sqrt(Sqr(Abs(X1-X2))+Sqr(Abs(Y1-Y2)));
end;

function Orientacion(Grados: double): string;
begin
  case Round(Grados) of
    0..10,350..360: Result:='N';  //norte
    11..34: Result:='N - NE';     //norte-noreste
    35..54: Result:='NE';         //noreste
    55..79: Result:='E - NE';     //este-noreste
    80..100: Result:='E';         //este
    101..124: Result:='E - SE';   //este-sureste
    125..144: Result:='SE';       //sureste
    145..169: Result:='S - SE';   //sur-sureste
    170..190: Result:='S';        //sur
    191..214: Result:='S - SW';   //sur-suroeste
    215..234: Result:='SW';       //suroeste
    235..259: Result:='W - SW';   //oeste-suroeste
    260..280: Result:='W';        //oeste
    281..304: Result:='W - NW';   //oeste-noroeste
    305..324: Result:='NW';       //noroeste
    325..349: Result:='N - NW';   //norte-noroeste
  end;
end;

function MetrosToKm(DistMetros: single): single;
begin
  Result:=DistMetros/1000;
end;

function SegundosToHoras(TmpSegs: single): single;
begin
  Result:=TmpSegs/3600;
end;

procedure RotarFlecha(Imagen: TCircle; Azimut: Double; var Azmt: Double);
var
  I,AntGrados,NvoGrados,Diferencia: Word;

  procedure MoverFlecha(I: word);
  var
    X: byte;
  begin
    Application.ProcessMessages;
    for X := 1 to 10 do;  //sólo hacer tiempo y nada más
    Imagen.RotationAngle:=I;
  end;

begin
  if Round(Azmt)=0 then AntGrados:=360
  else AntGrados:=Round(Azmt);
  if Azimut=0 then NvoGrados:=360
              else NvoGrados:=Round(Azimut);
  Diferencia:=Abs(NvoGrados-AntGrados);
  if Diferencia<=180 then
  begin
    if NvoGrados>AntGrados then
      for I:=AntGrados to NvoGrados do MoverFlecha(I)
    else
      for I:=AntGrados downto NvoGrados do MoverFlecha(I);
  end
  else
  begin
    Azmt:=AntGrados+NvoGrados;
    if AntGrados>NvoGrados then
      for I:=AntGrados to 360+NvoGrados do MoverFlecha(I)
    else
      for I:=AntGrados downto NvoGrados do MoverFlecha(I)
  end;
end;

end.

with Ada.Real_Time;

with Global_Initialization;
with System_Configuration;

with Sonar_Prod;                    pragma Unreferenced (Sonar_Prod);
with Vehicle;                       pragma Unreferenced (Vehicle);

procedure Midero is
   pragma Priority (System_Configuration.Main_Priority);
   use Ada.Real_Time;

begin
   Vehicle.Initialize;
   Global_Initialization.Critical_Instant.Signal (Epoch => Clock);
   loop
      delay until Time_Last;
   end loop;
end Midero;

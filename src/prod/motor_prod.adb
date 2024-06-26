with Ada.Unchecked_Conversion;
with HAL;
with Hardware_Config;

package body Motor_Prod is
   
   use Hardware_Config;
   
   Internal_Power : Power_Level        := 30 with Volatile;

   Internal_State : Current_State_T    := Running with Volatile, Async_Readers, Async_Writers;
   
   -- Internal motor basic facilities
   procedure Engage     (This : out Basic_Motor);
   procedure Stop       (This : out Basic_Motor);
   procedure Set_Motor  (This : out Basic_Motor; State : Motor_State);
   procedure Initialize 
     (This                 : out Basic_Motor;
      PWM_Timer            : not null access Timer;
      PWM_Output_Frequency : HAL.UInt32; -- in Hertz
      PWM_AF               : STM32.GPIO_Alternate_Function;
      PWM_Output           : GPIO_Point;
      PWM_Output_Channel   : Timer_Channel;
      --  discrete outputs to H-Bridge that control direction and stopping
      Polarity1            : GPIO_Point;
      Polarity2            : GPIO_Point);
   procedure Configure_Polarity_Control (This : GPIO_Point);

   ----------
   -- Stop --
   ----------
   
   procedure Stop (This : out Basic_Motor) is
   begin
      Clear (This.H_Bridge1);
      Clear (This.H_Bridge2);
      This.Power_Plant.Set_Duty_Cycle (100); -- Full power to Lock position 
   end Stop;

   ------------
   -- Engage --
   ------------

   procedure Engage (This : out Basic_Motor) is
   begin
      Set (This.H_Bridge1);
      Clear (This.H_Bridge2);
      This.Power_Plant.Set_Duty_Cycle (Value => Integer (Internal_Power));
   end Engage;

   ---------------
   -- Set_Motor --
   ---------------

   procedure Set_Motor (This : out Basic_Motor; State : Motor_State) is
   begin
      case State is
         when ON  => Engage (This);
         when OFF => Stop   (This);
      end case;
   end Set_Motor;

   ----------------
   -- Turn_Motor --
   ----------------

   procedure Turn_Motor (M1, M2, M3, M4 : in out Basic_Motor) is
   begin
      case Internal_State is
         when Braking =>
            M1.Set_Motor (OFF);
            M2.Set_Motor (OFF);
            M3.Set_Motor (OFF);
            M4.Set_Motor (OFF);
         when Running =>
            if not Set (M1.H_Bridge1) 
               and not Set (M2.H_Bridge1) 
               and not Set (M3.H_Bridge1)
               and not Set (M4.H_Bridge1)
            then
               M2.Set_Motor (ON);
               M2.Set_Motor (ON);
               M3.Set_Motor (ON);
               M4.Set_Motor (ON);
            else   
               null;
            end if;
      end case;
   end Turn_Motor;

   -------------------
   -- Encoder_Count --
   -------------------

   function Encoder_Count (This : Basic_Motor) return Motor_Encoder_Counts is
      function As_Motor_Encoder_Counts is new Ada.Unchecked_Conversion
        (Source => HAL.UInt32, Target => Motor_Encoder_Counts);
   begin
      return As_Motor_Encoder_Counts (Current_Count (This.Encoder));
   end Encoder_Count;


   ------------------------
   -- Set_Internal_State --
   ------------------------

   procedure Set_Internal_State (State : Current_State_T) is
   begin
      Internal_State := State;
   end Set_Internal_State;

   --------------------------------
   -- Configure_Polarity_Control --
   --------------------------------

   procedure Configure_Polarity_Control (This : GPIO_Point) is
      Config : GPIO_Port_Configuration;
   begin
      Config := (Mode           => Mode_Out,
                 Output_Type    => Push_Pull,
                 Resistors      => Floating,
                 Speed          => Speed_100MHz);
      This.Configure_IO (Config => Config);
      This.Lock;      -- Lock the current configuration of Pin until reset.
   end Configure_Polarity_Control;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize 
     (This                 : out Basic_Motor;
      PWM_Timer            : not null access Timer;
      PWM_Output_Frequency : HAL.UInt32; -- in Hertz
      PWM_AF               : STM32.GPIO_Alternate_Function;
      PWM_Output           : GPIO_Point;
      PWM_Output_Channel   : Timer_Channel;
      --  discrete outputs to H-Bridge that control direction and stopping
      Polarity1            : GPIO_Point;
      Polarity2            : GPIO_Point) is
   begin

      Configure_PWM_Timer (PWM_Timer, PWM_Output_Frequency);

      This.Power_Plant.Attach_PWM_Channel (PWM_Timer,  PWM_Output_Channel,
                                           PWM_Output, PWM_AF);
      This.Power_Plant.Enable_Output;
      This.Power_Channel := PWM_Output_Channel;

      This.H_Bridge1 := Polarity1;
      This.H_Bridge2 := Polarity2;

      Enable_Clock (Point => This.H_Bridge1);
      Enable_Clock (Point => This.H_Bridge2);

      Configure_Polarity_Control (This.H_Bridge1);
      Configure_Polarity_Control (This.H_Bridge2);

   end Initialize;

   -----------------------
   -- Initialize_Motors --
   -----------------------

   procedure Initialize_Motors (M1, M2, M3, M4 : in out Basic_Motor) is
   begin
      --  Motor Bottom Right
      Initialize (This => M1,
                  PWM_Timer            => Motor1_PWM_Engine_TMR,
                  PWM_Output_Frequency => Motor_PWM_Freq,
                  PWM_AF               => Motor1_PWM_Output_AF,
                  PWM_Output           => Motor1_PWM_Engine,
                  PWM_Output_Channel   => Motor1_PWM_Channel,
                  Polarity1            => Motor1_Polarity1,
                  Polarity2            => Motor1_Polarity2);
      --  Motor Bottom Left  
      Initialize (This => M2,
                  PWM_Timer            => Motor2_PWM_Engine_TMR,
                  PWM_Output_Frequency => Motor_PWM_Freq,
                  PWM_AF               => Motor2_PWM_Output_AF,
                  PWM_Output           => Motor2_PWM_Engine,
                  PWM_Output_Channel   => Motor2_PWM_Channel,
                  Polarity1            => Motor2_Polarity1,
                  Polarity2            => Motor2_Polarity2);
      --  --  Motor Top Left
      Initialize (This => M3,
                  PWM_Timer            => Motor3_PWM_Engine_TMR,
                  PWM_Output_Frequency => Motor_PWM_Freq,
                  PWM_AF               => Motor3_PWM_Output_AF,
                  PWM_Output           => Motor3_PWM_Engine,
                  PWM_Output_Channel   => Motor3_PWM_Channel,
                  Polarity1            => Motor3_Polarity1,
                  Polarity2            => Motor3_Polarity2);
      --  --  Motor Top Right
      Initialize (This => M4,
                  PWM_Timer            => Motor4_PWM_Engine_TMR,
                  PWM_Output_Frequency => Motor_PWM_Freq,
                  PWM_AF               => Motor4_PWM_Output_AF,
                  PWM_Output           => Motor4_PWM_Engine,
                  PWM_Output_Channel   => Motor4_PWM_Channel,
                  Polarity1            => Motor4_Polarity1,
                  Polarity2            => Motor4_Polarity2);
   end Initialize_Motors;

end Motor_Prod;


with Math_Utilities;

package body Recursive_Moving_Average_Filters_Discretes is

    procedure Safely_Add (Value : Sample; To : in out Accumulator) with Inline;
    --  Add sample Value (which can be negative) to the value of To, without
    --  overflowing

    procedure Safely_Subtract (Value : Sample; From : in out Accumulator) with Inline;
    --  Subtract sample Value (which can be negative) from the value of From,
    --  without overflowing

    -----------
    -- Value --
    -----------

    function Value (This : RMA_Filter) return Sample is
        (This.Averaged_Value);

    -----------
    -- Limit --
    -----------

    procedure Limit is new Math_Utilities.Bound_Integer_Value (T => Accumulator);

    ------------
    -- Insert --
    ------------

    procedure Insert (This : in out RMA_Filter;  New_Sample : Sample) is
        Average : Accumulator;
    begin
        if Empty (This.Samples) then
            Put (This.Samples, New_Sample);
            This.Total := Accumulator (New_Sample);
            This.Averaged_Value := New_Sample;
            return;
        end if;

        if Full (This.Samples) then
            --  Delete the oldest sample and remove its value from total (rather
            --  than iterate over all the samples in order to calculate a new
            --  total.
            declare
                Oldest : Sample;
            begin
                Get (This.Samples, Oldest);
                Safely_Subtract (Oldest, From => This.Total);
            end;
        end if;

        Put (This.Samples, New_Sample);

        Safely_Add (New_Sample, To => This.Total);

        Average := This.Total / Accumulator (Extent (This.Samples));
        Limit (Average, Accumulator (Sample'First), Accumulator (Sample'Last));
        This.Averaged_Value := Sample (Average);
    end Insert;

    ----------------
    -- Safely_Add --
    ----------------

    procedure Safely_Add (Value : Sample; To : in out Accumulator) is
    begin
        if Value > 0 then
            if To <= Accumulator'Last - Accumulator (Value) then
                To := To + Accumulator (Value);
            else
                To := Accumulator'Last;
            end if;
        else -- Value is negative (or zero)
            if To >= Accumulator'First - Accumulator (Value) then
                To := To + Accumulator (Value);
            else
                To := Accumulator'First;
            end if;
        end if;
    end Safely_Add;

    ---------------------
    -- Safely_Subtract --
    ---------------------

    procedure Safely_Subtract (Value : Sample; From : in out Accumulator) is
    begin
        if Value > 0 then
            if From >= Accumulator'First + Accumulator (Value) then
                From := From - Accumulator (Value);
            else
                From := Accumulator'First;
            end if;
        else -- Value is negative (or zero)
            if From <= Accumulator'Last + Accumulator (Value) then
                From := From - Accumulator (Value);
            else
                From := Accumulator'Last;
            end if;
        end if;
    end Safely_Subtract;

    -----------
    -- Reset --
    -----------

    procedure Reset (This : out RMA_Filter) is
    begin
        Reset (This.Samples);
        This.Averaged_Value := 0;
        This.Total := 0;
    end Reset;

end Recursive_Moving_Average_Filters_Discretes;

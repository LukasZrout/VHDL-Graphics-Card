--basicVGA
--VHDL FPGA Project for displaying colors on a LCD Display via the VGA standart,
--with the focus only laying on the proper timing
-- Input: 12MHz Clock
-- Outupt: HSYNC, VSYNC, R-, G-, B-, Channels;
-- Desired Resolution: 800x600
-- Desired (Horizontal) Refresh Rate: 56Hz
-- Desired Vertical Refresh Rate: 35.15625kHz
-- Horizontal Interpreted Pixels:           Vertical Pixels:
--          Visible:    800                 Visible:    600
--          Front Porch: 24                 Front Porch:  1
--          Back Porch: 128                 Back Porch:  22
--          Sync pulse:  72                 Sync pulse:   2
--          -----------------               -----------------
--                     1024                             625
-- The clock used for this is at 12Mhz. The pixel clock needed for the desired
-- resolution and refresh rate is at 36MHz. Therfor, only every 3 Pixels, the Information will be
-- updated. Although 1024 is not a multiple of 3, the next nearest 1023, which only skips out on 
-- 1 Pixel, should be fine. After some calculations, the actual screen refresh rate would then
-- be at around 56,3Hz.

-- Horizontal Generated Pixels:             Vertical Pixels:
--          Visible:     267                Visible:    600
--          Front Porch: 8                  Front Porch:  1
--          Back Porch:  43                 Back Porch:  22
--          Sync pulse:  24                 Sync pulse:   2
--          -----------------               -----------------
--                     342                             625
-- @author Lukas Zrout
-- @date 5.12.2020
--       May 12th 2020

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--todo: failsave integer minus; reset; precalculate values (y<=600-120 to y<=480);

--frage: wie reset bei register, letzter process
entity basicVGA is
    generic(
        -- inital X and Y and X- and Y-Direction values of the object
        -- base is the top left corner
        -- direction 1, equals to positive increment, 0 equals to negative increment
        initX:		integer:= 100; -- 0 to 267
        initY:		integer:= 200; -- 0 to 600
        initXdir:	BIT    := '1';
        initYdir:	BIT    := '0';

        obj:        BIT    := '1' -- 1 Circle; 0 Square;
    );
    port(
        CLK     : in    std_logic;
        HSYNC   : out   std_logic;
        VSYNC   : out 	std_logic;
        R       : out 	std_logic;
        G       : out 	std_logic;
        B       : out 	std_logic;
		beep    : out 	std_logic;
        nRES    : in 	std_logic
    );
end entity basicVGA;
architecture basicVGA_arch of basicVGA is
    signal HCOUNT : natural range 0 to 343 := 0;
    signal VCOUNT : natural range 0 to 626 := 0;
    signal x : 		natural range 0 to 266 :=initX;
    signal y : 		natural range 0 to 600 :=initY;
    signal xDir : 	BIT :=initXdir;
    signal yDir : 	BIT :=initYdir;
	signal frame : 	BIT := '0';
	 
	signal rgb, squareCol: std_logic_vector(2 downto 0):="000";
	 --signal squareCol:std_logic_vector(2 downto 0):="000";
	 
begin
	R<=rgb(0);
	G<=rgb(1);
    B<=rgb(2);
    squareCol<= "100" when xDir&yDir = "00" else
                "010" when xDir&yDir = "01" else
                "001" when xDir&yDir = "10" else
                "011" when xDir&yDir = "11";

    count_p:process(CLK, nRES) --counts and automatically resets the X and Y pixels
    begin
        if(nRES='1') then
				if rising_edge(CLK) then
					if(HCOUNT/=341) then
						 HCOUNT<=HCOUNT+1;
					else 
						HCOUNT<=0;
						if(VCOUNT/=625) then
							VCOUNT<=VCOUNT+1;
						else
							VCOUNT<=0;
						end if;
					end if;
				end if;
			elsif nRES='0' then
				VCOUNT<=0;
				HCOUNT<=0;
        end if;
    end process count_p;

    HSYNC_p:process(CLK, nRES) --SYNCS HSYNC at the correct timing
    begin
        if(nRES='1') then
				if rising_edge(CLK) then
					if (HCOUNT>275)and(HCOUNT<300)then
						 HSYNC<='0';
					else 
						 HSYNC<='1';
					end if;
				end if;
        elsif nRES='0' then
				HSYNC<='0';
			end if;
    end process HSYNC_p;

    VSYNC_p:process(CLK, nRES) --SYNCS VSYNC at the correct timing
    begin
        if(nRES='1') then
				if rising_edge(CLK) then
					if(VCOUNT>600)and(VCOUNT<604)then
						 VSYNC<='0';
						 frame<='0';
					else 
						 VSYNC<='1';
						 frame<='1';
					end if;
				end if;
        elsif nRES='0' then
				VSYNC<='0';
				frame<='0';
		  end if;
    end process VSYNC_p;
    
    color_p:process(CLK, nRES) --outputs the proper colors of the object and background
	variable xCirc : integer range -120 to 120;
	variable yCirc : integer range -120 to 120;
    begin
    if (nRES='1') then
	 if rising_edge(CLK) then
        if(HCOUNT>0) and (HCOUNT<268) and (VCOUNT>0) and (VCOUNT<601)then --if in pixel send timeframe
            if(HCOUNT>x)and(HCOUNT<x+40)and(VCOUNT>y)and(VCOUNT<y+120) then -- if current position is where object should be
                if(obj='1')then --if the desired object is a circle
                        xCirc:=(HCOUNT-x)*3-60;
                        yCirc:=(VCOUNT-y)-60;
                        if(xCirc*xCirc+yCirc*yCirc<=3601)then
                            rgb<=squareCol;
                        else
                            rgb<="111";
                        end if;			
                else  -- if the desired object is a square
                    rgb<=squareCol;
                end if;
		    else -- if current position isn't where a object should be
                rgb<="111";
            end if;
		else            -- if current position isn't in the pixel send timeframe
			rgb<="000";
		end if;
		end if;
    elsif nRES='0' then
		rgb<="000";
	 end if;
    end process color_p;
	 
	 dir_p:process(frame, nRES)
    begin
	 if(nRES='1') then
		if(frame='1') and frame'event
			then
				beep<='0';
				if(x>=266-40) then
                xDir<='0';
					 beep<='1';
            elsif(x<=1) then
                xDir<='1';
					 beep<='1';
            end if;

            if(y>=600-120) then
                yDir<='0';
					 beep<='1';
            elsif (y<=1) then
                yDir<='1';
					 beep<='1';
            end if; 
		end if;
		elsif nRES='0' then
			xDir<=initXdir;
			yDir<=initYdir;
			beep<='0';
		end if;
    end process dir_p;

    run_p:process(frame,nRES)
    begin
		if(nRES='1') then
			if(frame='1') and frame'event then
				 if(xDir='1') then
					x<=x+1;
				else 
					x<=x-1;
				end if;

				 if(yDir='1') then
					y<=y+1;
				 else
					y<=y-1;
				end if;
			end if;
		elsif nRES='0' then
			x<=initX;
			y<=initY;
		end if;
	end process run_p;
end architecture basicVGA_arch;
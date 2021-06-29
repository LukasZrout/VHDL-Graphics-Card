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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
--todo: failsave integer minus; reset; precalculate values (y<=600-120 to y<=480);

--frage: wie reset bei register, letzter process
ENTITY basicVGA IS
	GENERIC (
		-- inital X and Y and X- and Y-Direction values of the object
		-- base is the top left corner
		-- direction 1, equals to positive increment, 0 equals to negative increment
		initX : INTEGER := 100; -- 0 to 267
		initY : INTEGER := 200; -- 0 to 600
		initXdir : BIT := '1';
		initYdir : BIT := '0';

		obj : BIT := '1' -- 1 Circle; 0 Square;
	);
	PORT (
		CLK : IN STD_LOGIC;
		HSYNC : OUT STD_LOGIC;
		VSYNC : OUT STD_LOGIC;
		R : OUT STD_LOGIC;
		G : OUT STD_LOGIC;
		B : OUT STD_LOGIC;
		beep : OUT STD_LOGIC;
		nRES : IN STD_LOGIC
	);
END ENTITY basicVGA;
ARCHITECTURE basicVGA_arch OF basicVGA IS
	SIGNAL HCOUNT : NATURAL RANGE 0 TO 343 := 0;
	SIGNAL VCOUNT : NATURAL RANGE 0 TO 626 := 0;
	SIGNAL x : NATURAL RANGE 0 TO 266 := initX;
	SIGNAL y : NATURAL RANGE 0 TO 600 := initY;
	SIGNAL xDir : BIT := initXdir;
	SIGNAL yDir : BIT := initYdir;
	SIGNAL frame : BIT := '0';

	SIGNAL rgb, squareCol : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
	--signal squareCol:std_logic_vector(2 downto 0):="000";

BEGIN
	R <= rgb(0);
	G <= rgb(1);
	B <= rgb(2);
	squareCol <= "100" WHEN xDir & yDir = "00" ELSE
		"010" WHEN xDir & yDir = "01" ELSE
		"001" WHEN xDir & yDir = "10" ELSE
		"011" WHEN xDir & yDir = "11";

	count_p : PROCESS (CLK, nRES) --counts and automatically resets the X and Y pixels
	BEGIN
		IF (nRES = '1') THEN
			IF rising_edge(CLK) THEN
				IF (HCOUNT /= 341) THEN
					HCOUNT <= HCOUNT + 1;
				ELSE
					HCOUNT <= 0;
					IF (VCOUNT /= 625) THEN
						VCOUNT <= VCOUNT + 1;
					ELSE
						VCOUNT <= 0;
					END IF;
				END IF;
			END IF;
		ELSIF nRES = '0' THEN
			VCOUNT <= 0;
			HCOUNT <= 0;
		END IF;
	END PROCESS count_p;

	HSYNC_p : PROCESS (CLK, nRES) --SYNCS HSYNC at the correct timing
	BEGIN
		IF (nRES = '1') THEN
			IF rising_edge(CLK) THEN
				IF (HCOUNT > 275) AND (HCOUNT < 300) THEN
					HSYNC <= '0';
				ELSE
					HSYNC <= '1';
				END IF;
			END IF;
		ELSIF nRES = '0' THEN
			HSYNC <= '0';
		END IF;
	END PROCESS HSYNC_p;

	VSYNC_p : PROCESS (CLK, nRES) --SYNCS VSYNC at the correct timing
	BEGIN
		IF (nRES = '1') THEN
			IF rising_edge(CLK) THEN
				IF (VCOUNT > 600) AND (VCOUNT < 604) THEN
					VSYNC <= '0';
					frame <= '0';
				ELSE
					VSYNC <= '1';
					frame <= '1';
				END IF;
			END IF;
		ELSIF nRES = '0' THEN
			VSYNC <= '0';
			frame <= '0';
		END IF;
	END PROCESS VSYNC_p;

	color_p : PROCESS (CLK, nRES) --outputs the proper colors of the object and background
		VARIABLE xCirc : INTEGER RANGE -120 TO 120;
		VARIABLE yCirc : INTEGER RANGE -120 TO 120;
	BEGIN
		IF (nRES = '1') THEN
			IF rising_edge(CLK) THEN
				IF (HCOUNT > 0) AND (HCOUNT < 268) AND (VCOUNT > 0) AND (VCOUNT < 601) THEN --if in pixel send timeframe
					IF (HCOUNT > x) AND (HCOUNT < x + 40) AND (VCOUNT > y) AND (VCOUNT < y + 120) THEN -- if current position is where object should be
						IF (obj = '1') THEN --if the desired object is a circle
							xCirc := (HCOUNT - x) * 3 - 60;
							yCirc := (VCOUNT - y) - 60;
							IF (xCirc * xCirc + yCirc * yCirc <= 3601) THEN
								rgb <= squareCol;
							ELSE
								rgb <= "111";
							END IF;
						ELSE -- if the desired object is a square
							rgb <= squareCol;
						END IF;
					ELSE -- if current position isn't where a object should be
						rgb <= "111";
					END IF;
				ELSE -- if current position isn't in the pixel send timeframe
					rgb <= "000";
				END IF;
			END IF;
		ELSIF nRES = '0' THEN
			rgb <= "000";
		END IF;
	END PROCESS color_p;

	dir_p : PROCESS (frame, nRES)
	BEGIN
		IF (nRES = '1') THEN
			IF (frame = '1') AND frame'event
				THEN
				beep <= '0';
				IF (x >= 266 - 40) THEN
					xDir <= '0';
					beep <= '1';
				ELSIF (x <= 1) THEN
					xDir <= '1';
					beep <= '1';
				END IF;

				IF (y >= 600 - 120) THEN
					yDir <= '0';
					beep <= '1';
				ELSIF (y <= 1) THEN
					yDir <= '1';
					beep <= '1';
				END IF;
			END IF;
		ELSIF nRES = '0' THEN
			xDir <= initXdir;
			yDir <= initYdir;
			beep <= '0';
		END IF;
	END PROCESS dir_p;

	run_p : PROCESS (frame, nRES)
	BEGIN
		IF (nRES = '1') THEN
			IF (frame = '1') AND frame'event THEN
				IF (xDir = '1') THEN
					x <= x + 1;
				ELSE
					x <= x - 1;
				END IF;

				IF (yDir = '1') THEN
					y <= y + 1;
				ELSE
					y <= y - 1;
				END IF;
			END IF;
		ELSIF nRES = '0' THEN
			x <= initX;
			y <= initY;
		END IF;
	END PROCESS run_p;
END ARCHITECTURE basicVGA_arch;

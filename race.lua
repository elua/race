-------------------------------------------------------------------------------
--
--		eLua Race Game
--
--
--													LED Lab @ PUC-Rio
--																2010
--
--  v0.0.2
--    This is the second version of this new eLua game!
--      + Multiple Levels
--      - It does have checkpoints
--      - The speed and controls are being adjusted
--
--  To Do:
--    - Code cleanup
--    - Button pooling while waiting
--    - Comments, comments and more comments
--
-------------------------------------------------------------------------------
local MAX_X = 18
local MAX_Y = 12
local tmrid = 2
local COL_SIZE = math.ceil( MAX_Y / 4 )
local CAR_CHAR = ">"
local WALL_CHAR = "*"

local pressed = {}

local level
local level_size
local level_buffer = {}

local levels = { "level1", "level2" }

local NUM_OF_LEVELS = #levels



-- Init pio function
-- It must be substituted by this line:
-- kit = require( pd.platform() )
-- This only exists because of an error in EK-LM3S8962.lua file
function init()
BTN_UP      = pio.PE_0
BTN_DOWN    = pio.PE_1
BTN_LEFT    = pio.PE_2
BTN_RIGHT   = pio.PE_3
BTN_SELECT  = pio.PF_1

btn_pressed = function( button )
  return pio.pin.getval( button ) == 0
end

LED_1 = pio.PF_0

disp = lm3s.disp

pio.pin.setdir( pio.INPUT, BTN_UP, BTN_DOWN, BTN_LEFT, BTN_RIGHT, BTN_SELECT )
pio.pin.setpull( pio.PULLUP, BTN_UP, BTN_DOWN, BTN_LEFT, BTN_RIGHT, BTN_SELECT )

pio.pin.setdir( pio.OUTPUT, LED_1 )
end

function initLevelBuffer( col )
  for i = 0, MAX_X + 1 do
    local col = string.sub( level, COL_SIZE*( col + i ) + 1, COL_SIZE * ( col + i + 1 ) )
    loadstring( "c = 0x"..col )()
    level_buffer[ i ] = c
  end
end

function updateAll()
  collumn = collumn + 1
  updateCarPos()
  updateScreen()
end

function updateScreen()
  local col = string.sub( level, COL_SIZE * ( collumn + MAX_X ) + 1 , COL_SIZE * ( collumn + MAX_X + 1 ) )
  loadstring( "c = 0x"..col )()
  updateLevelBuffer( c )
  for i = MAX_X - 1, 0, -1 do
  --local col = string.sub( level, COL_SIZE*collumn + COL_SIZE * i, COL_SIZE * collumn + COL_SIZE * i + COL_SIZE )
  --loadstring( "c = 0x"..col )()
    for j = 0, MAX_Y - 1 do
      if j ~= cy or i ~= 0 then
        if bit.isset( level_buffer[ i ], j ) then
          disp.print( WALL_CHAR, i*6, j*8, 8 )
        else
          disp.print( " ", i*6, j*8, 0 )
        end
      end
    end
  end
end

function updateLevelBuffer( col, ... )
  if not col then
    return
  end
  for i = 0, MAX_X - 2 do
    level_buffer[ i ] = level_buffer[ i + 1]
 -- table.remove( level_buffer, 1 )
 -- table.insert( level_buffer, col )
  end
  level_buffer[ MAX_X - 1 ] = col
  updateLevelBuffer( ... )
end

function loadLevel( level_name )
  dofile( "/rom/"..level_name..".lua" )
  level = _G[ level_name ]
  level_size = string.len( level ) / 3
end

-- Car functions
function drawCar( y, color, movement )
  if ( movement == 0 ) then
    disp.print( CAR_CHAR, 0, y * 8, color)
  elseif ( movement > 0 ) then			-- Car moving Down
    disp.print( CAR_CHAR, 0, ( y - 1 ) * 8, 0 )
    disp.print( CAR_CHAR, 0, y * 8, color )
  elseif ( movement < 0 ) then		-- Car moving Up
    disp.print( CAR_CHAR, 0, ( y + 1 ) * 8, 0 )
    disp.print( CAR_CHAR, 0, y * 8, color )
  end
end

function updateCarPos()
  local mov = 0
  if btn_pressed( BTN_UP ) then
    if ( cy > 0 ) then
      mov = -1
    end
  elseif btn_pressed( BTN_DOWN ) then
    if cy < MAX_Y - 1 then
      mov = 1
    end
  end
  cy = cy + mov
  drawCar( cy, 11, mov )
end




function drawWall( x, y )
  for i = 0, y, 7 do
    disp.print( "|", xcanvas + 1, i, 0 )
  end
  xcanvas = x
  for i = 0, y, 7 do
    disp.print( "|", xcanvas + 1, i, 6 )
  end

end

function buttonClicked( button )
  if btn_pressed( button ) then
    pressed[ button ] = true
  else
    if pressed[ button ] then
      pressed[ button ] = false
      return true
    end
    pressed[ button ] = false
  end
  return false
end

------------ MAIN ------------
init()

disp.init( 1000000 )

collectgarbage("collect")

local checkpoint = 0
local time = 0
local best_time
local current_level_id = 1
local delayTime = 100000												-- This value is used for the main delay, to make the game speed faster or slower



while true do

  loadLevel( levels[ current_level_id ] )
  ycanvas = 96
  cy = MAX_Y / 2												-- Car's Y position ( X position not needed, always 0 )
  collumn = checkpoint - 1
  win = false
  LEVEL_X = level_size - ( MAX_X + 1 )

  initLevelBuffer( checkpoint )

  timeStart = tmr.start( tmrid )

  disp.clear()

  for i = 0, ycanvas, 7 do
    disp.print( "|", 106, i, 6 )
  end

  timeStart = tmr.start( tmrid )

  while ( true ) do
    updateAll()
  --local col = string.sub( level, COL_SIZE*collumn, COL_SIZE*collumn + COL_SIZE )
  --loadstring( "c = 0x"..col )()
    if level_buffer[ 0 ] == 0xFFF then
      checkpoint = collumn
    elseif bit.isset( level_buffer[ 0 ], cy ) then
      break
    end

    if collumn == LEVEL_X then
      disp.print( "Congratulations!", 10, 48, 15 )
      tmr.delay( 0, 3000000 )
      disp.print( "Congratulations!", 10, 48, 0 )
      current_level_id = current_level_id + 1
      win = true
      break
    end
    tmr.delay( 0, delayTime )


    if buttonClicked( BTN_RIGHT ) and delayTime > 0 then
      delayTime = delayTime - 20000
      print(delayTime)
    end
    if buttonClicked( BTN_LEFT ) and delayTime < 100000 then
      delayTime = delayTime + 20000
      print(delayTime)
    end

    local dt = tmr.gettimediff( tmrid, timeStart, tmr.read( tmrid ) )
    if dt >= 1000000 then
      time = math.floor( time + ( dt / 1000000 ) )
      timeStart = tmr.read( tmrid )
    end
    disp.print( time, 110, 0, 6 )

    collectgarbage("collect")
  end
-------------------------------------------
-- End of Game
-------------------------------------------

  disp.clear()
  if not win then
    disp.print( "You died :(", 30, 20, 11 )
    disp.print( "Current time is "..tostring(time), 5, 40, 11 )
    disp.print( "SELECT to continue", 6, 70, 11 )
  else
    disp.print( "Level complete", 20, 20, 11 )
    disp.print( "Your time is "..tostring(time), 15, 40, 11 )
    disp.print( "SELECT to Next Level", 6, 70, 11 )
    if current_level_id > NUM_OF_LEVELS then
      if ( not best_time ) or ( time < best_time ) then
        best_time = time
      end
      disp.clear()
      disp.print( "Finnish!!!", 30, 20, 11 )
      disp.print( "Time was "..tostring( time ), 15, 40, 11 )
      disp.print( "Best time: "..tostring( best_time ), 15, 50, 11 )
      disp.print( "SELECT to Play Again", 6, 70, 11 )
      current_level_id = 1
      checkpoint = 0
      time = 0
      delayTime = 100000
    end
  end
  while true do
    if btn_pressed( BTN_SELECT ) then
      break
    end
  end

end

disp.off()

-- kateqwerty's turtle code. GPL'd
-- diglib v0.14

fuelType=1000 --lava cell
--fuelType=80 --coal

x=0 --do not change these!
y=0
z=0
-- d:movement direction (clockwise)
-- 0=towards increasing y
-- 1=towards increasing x
-- 2=towards decreasing y
-- 3=towards decreasing x
d=0
safetyMargin=20 --for when to refuel
digRetry=30 --how much to retry digging
errm=0 --0=abort, 1=keep retrying

--
-- generic utility functions
--

function getpos()
	result={}
	result.x=x
	result.y=y
	result.z=z
	result.d=d
	return result
end

function printPos()
	print("x=",x," y=",y," z=",z," d=",d)
end

function up()
	limit=digRetry
	if errm==1 then limit=99999999 end
	for i=1,limit do
		if turtle.up() then
			z=z+1
			return true
		end
		turtle.attackUp() --TODO: check it really works
		sleep(1)
	end
	return false
end

function down()
	limit=digRetry
	if errm==1 then limit=99999999 end
	for i=1,limit do
		if turtle.down() then
			z=z-1
			return true
		end
		turtle.attackDown() --TODO: check it really works
		sleep(1)
	end
	return false
end

function forward()
	limit=digRetry
	if errm==1 then limit=99999999 end
	for i=1,limit do
		if turtle.forward() then
			if d==0 then
				y=y+1
			elseif d==1 then
				x=x+1
			elseif d==2 then
				y=y-1
			elseif d==3 then
				x=x-1
			end
			return true
		end
		turtle.attack() --TODO: check it really works
		sleep(1)
	end
	return false
end

function turnRight()
	while true do
		if turtle.turnRight() then break end
		print(">>>>> turnRight()==false <<<<<")
	end
	d=d+1
	if d>3 then d=0 end
end

function turnLeft()
	while true do
		if turtle.turnLeft() then break end
		print(">>>>> turnLeft()==false <<<<<")
	end
	d=d-1
	if d<0 then d=3 end
end

function direction(dir)
	while d~=dir do
		turnLeft()
	end
end

function refuel()
	fc=turtle.getFuelLevel()
	if fc<safetyMargin and turtle.getItemCount(1)>1 then
		turtle.select(1)
		turtle.refuel(1)
	end
	return fc
end

--side effect: refuels
function fuel()
	--assuming fuel must be placed at 1
	f=turtle.getItemCount(1)
	--the -1 is a trick: never consume
	--the last item, or when you dig
	--other stuff may get into that
	--place and fuck up the fuel count
	f=(f-1)*fuelType
	if f<0 then
		print("Error: put fuel in item 1")
		exit()
	end
	return f+refuel()
end

--side effect: refuels
function fuelCheck()
	if fuel()-safetyMargin<distance() then
		fail("Not enough fuel")
	end
end

function distance()
	return x+y+z
end

function freeSlots()
	result=0
	for i=1,16 do
		if turtle.getItemCount(i)==0 then
			result=result+1
		end
	end
	return result
end

function home()
	errm=1 --if objects in the way keep retrying

	if z<0 then up() end
	if z>0 then down() end --for createFloorAndCeiling()

	--always do y first, for compatibility with
	--first level digging function
	if y>0 then
		direction(2)
		while y>0 do
			forward()
			refuel()
		end
	end
	if y<0 then
		direction(0)
		while y<0 do
			forward()
			refuel()
		end
	end
	if x>0 then
		direction(3)
		while x>0 do
			forward()
			refuel()
		end
	end
	if x<0 then
		direction(1)
		while x<0 do
			forward()
			refuel()
		end
	end
	while z>0 do down(); refuel() end
	while z<0 do up(); refuel() end
	direction(2)
	errm=0 --if objects in the way fail
end

function setpos(pos)
	--only works for going down or pos.z==0, not up (pos.z>0)
	if pos.z>0 then fail("fixme") end
	if pos.z<0 then
		while z-1>pos.z do
			while not down() do
				obstacle()
			end
			fuelCheck()
		end
	end
	--always do x first, for compatibility with
	--first level digging function
	if x>pos.x then
		direction(3)
	else
		direction(1) 
	end
	while x~=pos.x do
		while not forward() do
			obstacle()
		end
		fuelCheck()
	end
	if y>pos.y then
		direction(2)
	else
		direction(0)
	end
	while y~=pos.y do
		while not forward() do
			obstacle()
		end
		fuelCheck()
	end
	if pos.z<0 then
		while not down() do
			obstacle()
		end
	end
	direction(pos.d)
end

function fail(cause)
	print("----------")
	print(cause)
	printPos()
	home()
	exit()
end

function obstacle()
	print("----------")
	print("Found obstacle @")
	printPos()
	pos=getpos()
	home()
	print("Type enter to retry")
	io.read()
	setpos(pos)
end

function emptySlots()
	print("----------")
	print("No free slots")
	printPos()
	pos=getpos()
	home()

	success=true
	if turtle.detect() then
		for i=2,16 do
			turtle.select(i)
			if not turtle.drop() then
				success=false
			end
		end
	else
		success=false
	end
	
	if success then
		print("Placed in chest, going on")
	else
		print("No chest found, or chest full, empty")
		print("slots manually and type enter to restart")
		io.read()
	end
	setpos(pos) 
end

--
-- functions for digging down
--

function digForwardAndCheck()
	if turtle.detect() then turtle.dig() end
	if freeSlots()==0 then
	 emptySlots()
	end
	fuelCheck()
	while not forward() do
		obstacle()
	end
end

function digDownAndCheck()
	if turtle.detectDown() then turtle.digDown() end
	if freeSlots()==0 then
		emptySlots()
	end
	fuelCheck()
	while not down() do
		obstacle()
	end
end

function digLevelImpl(xc,yc,dir,turn)
	direction(dir)
	for i=1,xc do
		for j=1,yc-1 do digForwardAndCheck() end
		if i<xc then
			if i%2==turn then
				turnLeft()
				digForwardAndCheck()
				turnLeft()
			else
				turnRight()
				digForwardAndCheck()
				turnRight()
			end
		end
	end
end

function digLevel(xc,yc)
	digDownAndCheck()
	if x==0 and y==0 then
		digLevelImpl(xc,yc,0,0)
	elseif x>0 and y==0 then
		digLevelImpl(xc,yc,0,1)
	elseif x==0 and y>0 then
		digLevelImpl(xc,yc,2,1)
	else
		digLevelImpl(xc,yc,2,0)
	end
end

--
-- functions for digging two levels
--

function digTwoLevelsForwardAndCheck()
	if turtle.detect() then turtle.dig() end
	if freeSlots()==0 then
	 emptySlots()
	end
	if turtle.detectDown() then turtle.digDown() end
	if freeSlots()==0 then
	 emptySlots()
	end
	fuelCheck()
	while not forward() do
		obstacle()
	end
end

function digTwoLevelsImpl(xc,yc,dir,turn)
	direction(dir)
	for i=1,xc do
		for j=1,yc-1 do digTwoLevelsForwardAndCheck() end
		if i<xc then
			if i%2==turn then
				turnLeft()
				digTwoLevelsForwardAndCheck()
				turnLeft()
			else
				turnRight()
				digTwoLevelsForwardAndCheck()
				turnRight()
			end
		end
	end
end

function digTwoLevels(xc,yc)
	digDownAndCheck()
	if x==0 and y==0 then
		digTwoLevelsImpl(xc,yc,0,0)
	elseif x>0 and y==0 then
		digTwoLevelsImpl(xc,yc,0,1)
	elseif x==0 and y>0 then
		digTwoLevelsImpl(xc,yc,2,1)
	else
		digTwoLevelsImpl(xc,yc,2,0)
	end
	digDownAndCheck()
end

--
-- functions for digging first level (gravel-aware)
--

function firstLevelDigForwardAndCheck()
	for k=1,digRetry do
		if not turtle.dig() then break end
		sleep(0.5) --gravel may fall, so wait and redig
		if k>=digRetry then
			fail("Dig retry count expired @ first level")
		end
	end
	if freeSlots()==0 then
		emptySlots()
	end
	if fuel()-safetyMargin<distance() then
		fail("No fuel @ first level")
	end
	while not forward() do
		print("Obstacle @ first level")
		obstacle()
	end
end

function firstLevelForwardAndCheck()
	if fuel()-safetyMargin<distance() then
		fail("No fuel @ first level")
	end
	while not forward() do
		print("Obstacle @ first level")
		obstacle()
	end
end

function digFirstLevel(xc,yc)
	for i=1,xc do
		direction(0)
		for j=1,yc-1 do
			firstLevelDigForwardAndCheck()
		end
		direction(2)
		for j=1,yc-1 do
			firstLevelForwardAndCheck()
		end
		if i~=xc then
			direction(1)
			firstLevelDigForwardAndCheck()
		end
	end
	direction(3)
	for i=1,xc-1 do
		firstLevelForwardAndCheck()
	end
	direction(0)
end

--
-- functions for placing blocks
--

selected=2 --selected slot where to pick blocks

function placeBlock(where)
	while turtle.getItemCount(selected)==0 and selected<17 do
		selected=selected+1
	end
	if selected>16 then
		fail("no items to place")
	end
	turtle.select(selected)
	if where==0 then
		turtle.placeDown()
	else
		turtle.placeUp()
	end
end

function placeBlockAndForward(where)
	placeBlock(where)
	fuelCheck()
	while not forward() do
		obstacle()
	end
end

function createPlane(xc,yc,where)
	for i=1,xc do
		for j=1,yc-1 do placeBlockAndForward(where) end
		if i<xc then
			if i%2==0 then
				turnLeft()
				placeBlockAndForward(where)
				turnLeft()
			else
				turnRight()
				placeBlockAndForward(where)
				turnRight()
			end
		end
	end
	placeBlock(where)
end

function createFloor(xc,yc)
	selected=2
	createPlane(xc,yc,0)
end

function createFloorAndCeiling(xc,yc,zc)
	if zc<2 then fail("zc must be > 2") end
	selected=2
	createPlane(xc,yc,0)
	home()
	direction(0) --home leaves the turtle with d=2
	for k=1,zc-1 do
		while not up() do
			obstacle()
		end
	end
	createPlane(xc,yc,1)
end
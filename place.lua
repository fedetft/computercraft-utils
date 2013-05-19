-- kateqwerty's turtle code. GPL'd
-- place v0.14

dofile "diglib"

xc=20 --x of square to dig
yc=20 --y of square to dig
zc=3 --distance between planes (if ceiling=true)
ceiling=true --create also ceiling

print("Initial fuel=",fuel())
if not ceiling then
	createFloor(xc,yc)
else
	createFloorAndCeiling(xc,yc,zc)
end
home()
print("Success")
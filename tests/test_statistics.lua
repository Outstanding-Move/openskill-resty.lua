package.path = "../src/?.lua;" .. package.path

local statistics = require("Statistics")

local EPSILON = 1e-6

local function approx(a, b, eps)
	eps = eps or EPSILON
	return math.abs(a - b) < eps
end

-- phiMajor is cdf of standard normal
assert(approx(statistics.phiMajor(0), 0.5), "phiMajor(0) should be 0.5")
assert(statistics.phiMajor(-5) < 0.001, "phiMajor(-5) should be near 0")
assert(statistics.phiMajor(5) > 0.999, "phiMajor(5) should be near 1")

-- phiMajorInverse is ppf of standard normal
assert(approx(statistics.phiMajorInverse(0.5), 0), "phiMajorInverse(0.5) should be 0")
assert(approx(statistics.phiMajorInverse(statistics.phiMajor(1.0)), 1.0, 1e-3), "phiMajorInverse(phiMajor(1)) should round-trip")

-- phiMinor is pdf of standard normal
assert(approx(statistics.phiMinor(0), 1 / math.sqrt(2 * math.pi)), "phiMinor(0) should be 1/sqrt(2pi)")

-- v function returns a number
local v = statistics.v(1, 0.5)
assert(type(v) == "number", "v(1, 0.5) should return a number")

-- v with very small denom (triggers the guard)
local v2 = statistics.v(-40, 0)
assert(type(v2) == "number", "v(-40, 0) should return a number (guard path)")

-- w function returns a number
local w = statistics.w(1, 0.5)
assert(type(w) == "number", "w(1, 0.5) should return a number")
assert(w >= 0, "w(1, 0.5) should be non-negative")

-- w with very small denom
local w2 = statistics.w(-40, 0)
assert(w2 == 1, "w(-40, 0) should be 1 (guard: x < 0)")
local w3 = statistics.w(40, 0)
assert(w3 == 0, "w(40, 0) should be 0 (guard: x >= 0)")

-- vt function
local vt = statistics.vt(1, 0.5)
assert(type(vt) == "number", "vt(1, 0.5) should return a number")

-- vt with small b (triggers guard)
local vt2 = statistics.vt(0.001, 0)
assert(type(vt2) == "number", "vt(0.001, 0) should return a number (guard path)")

-- vt with negative x and small b
local vt3 = statistics.vt(-0.001, 0)
assert(type(vt3) == "number", "vt(-0.001, 0) should return a number (guard path)")

-- wt function
local wt = statistics.wt(1, 0.5)
assert(type(wt) == "number", "wt(1, 0.5) should return a number")

-- wt with very small b (triggers guard)
local wt2 = statistics.wt(40, 0)
assert(wt2 == 1, "wt(40, 0) should be 1 (guard path)")

-- phiMajor: symmetry property at 6 points
for _, x in ipairs({0.5, 1, 1.5, 2, 2.5, 3}) do
	assert(approx(statistics.phiMajor(x) + statistics.phiMajor(-x), 1, 1e-6),
		"phiMajor(x)+phiMajor(-x) should be 1 for x=" .. x)
end

-- phiMajor: known values at 1 and 2
assert(approx(statistics.phiMajor(1), 0.8413447, 1e-4), "phiMajor(1) should be ~0.8413")
assert(approx(statistics.phiMajor(2), 0.9772499, 1e-4), "phiMajor(2) should be ~0.9772")

-- phiMajorInverse: round-trip at 5 probability points
for _, p in ipairs({0.1, 0.25, 0.5, 0.75, 0.9}) do
	assert(approx(statistics.phiMajor(statistics.phiMajorInverse(p)), p, 1e-3),
		"phiMajor(phiMajorInverse(p)) should round-trip for p=" .. p)
end

-- phiMajorInverse: known inverse values
assert(approx(statistics.phiMajorInverse(0.975), 1.96, 0.01), "phiMajorInverse(0.975) should be ~1.96")
assert(approx(statistics.phiMajorInverse(0.025), -1.96, 0.01), "phiMajorInverse(0.025) should be ~-1.96")

-- phiMinor: symmetry at 3 points
for _, x in ipairs({0.5, 1.5, 3}) do
	assert(approx(statistics.phiMinor(x), statistics.phiMinor(-x), 1e-6),
		"phiMinor should be symmetric for x=" .. x)
end

-- phiMinor: known values
assert(approx(statistics.phiMinor(1), 0.2419707, 1e-4), "phiMinor(1) should be ~0.2420")
assert(approx(statistics.phiMinor(2), 0.0539910, 1e-4), "phiMinor(2) should be ~0.0540")

-- phiMinor: extreme values -> ~0
assert(statistics.phiMinor(10) < 1e-10, "phiMinor(10) should be near 0")
assert(statistics.phiMinor(-10) < 1e-10, "phiMinor(-10) should be near 0")

-- v(): positive inputs
local vPos = statistics.v(2, 0.5)
assert(type(vPos) == "number", "v(2, 0.5) should return a number")
assert(vPos > 0, "v(2, 0.5) should be positive")

-- v(): negative inputs (guard)
local vNeg = statistics.v(-30, 0)
assert(type(vNeg) == "number", "v(-30, 0) should return a number")

-- v(): equal x and t
local vEq = statistics.v(1, 1)
assert(type(vEq) == "number", "v(1, 1) should return a number")

-- w(): non-negativity for 6 input pairs
for _, pair in ipairs({{0, 0}, {1, 0.5}, {2, 1}, {-1, 0.5}, {0.5, 0.5}, {3, 1}}) do
	local wVal = statistics.w(pair[1], pair[2])
	assert(wVal >= 0, "w() should be non-negative for x=" .. pair[1] .. " t=" .. pair[2])
end

-- w(): relationship with v: w = v*(v + (x-t))
local xw, tw = 1.5, 0.3
local vForW = statistics.v(xw, tw)
local wForW = statistics.w(xw, tw)
assert(approx(wForW, vForW * (vForW + (xw - tw)), 1e-6), "w should equal v*(v+(x-t))")

-- vt(): antisymmetry: vt(x,t) = -vt(-x,t)
for _, pair in ipairs({{1, 0.5}, {2, 1}, {0.5, 0.3}}) do
	local vtPos = statistics.vt(pair[1], pair[2])
	local vtNeg = statistics.vt(-pair[1], pair[2])
	assert(approx(vtPos, -vtNeg, 1e-6), "vt should be antisymmetric for x=" .. pair[1])
end

-- vt(): x=0 returns 0
assert(approx(statistics.vt(0, 0.5), 0, 1e-6), "vt(0, t) should be 0")

-- wt(): non-negativity for 4 pairs
for _, pair in ipairs({{0, 0.5}, {1, 0.5}, {-1, 0.5}, {2, 1}}) do
	local wtVal = statistics.wt(pair[1], pair[2])
	assert(wtVal >= 0, "wt() should be non-negative for x=" .. pair[1] .. " t=" .. pair[2])
end

-- wt(): small-b guard
local wtSmallB = statistics.wt(40, 0)
assert(wtSmallB == 1, "wt(40, 0) should be 1 (guard)")

-- wt(): bounded at center (0 <= wt <= 1 for moderate inputs)
local wtCenter = statistics.wt(0, 1)
assert(wtCenter >= 0 and wtCenter <= 1, "wt(0, 1) should be in [0, 1]")

print("test_statistics: PASSED")

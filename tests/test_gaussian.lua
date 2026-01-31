package.path = "../src/?.lua;" .. package.path

local gaussian = require("Gaussian")

local EPSILON = 1e-6

local function approx(a, b, eps)
	eps = eps or EPSILON
	return math.abs(a - b) < eps
end

-- construction
local g = gaussian.new(0, 1)
assert(g.mean == 0, "standard normal mean should be 0")
assert(g.variance == 1, "standard normal variance should be 1")
assert(g.standardDeviation == 1, "standard normal stddev should be 1")

local g2 = gaussian.new(10, 4)
assert(g2.mean == 10, "g2 mean should be 10")
assert(g2.variance == 4, "g2 variance should be 4")
assert(approx(g2.standardDeviation, 2), "g2 stddev should be 2")

-- variance must be > 0
local ok = pcall(function() gaussian.new(0, 0) end)
assert(not ok, "zero variance should error")
local ok2 = pcall(function() gaussian.new(0, -1) end)
assert(not ok2, "negative variance should error")

-- pdf of standard normal at 0
assert(approx(g:pdf(0), 1 / math.sqrt(2 * math.pi)), "pdf(0) should be 1/sqrt(2pi)")

-- cdf of standard normal
assert(approx(g:cdf(0), 0.5), "cdf(0) should be 0.5")
assert(g:cdf(-5) < 0.001, "cdf(-5) should be near 0")
assert(g:cdf(5) > 0.999, "cdf(5) should be near 1")

-- ppf (inverse cdf) of standard normal
assert(approx(g:ppf(0.5), 0), "ppf(0.5) should be 0")
assert(approx(g:ppf(g:cdf(1.5)), 1.5, 1e-3), "ppf(cdf(1.5)) should round-trip to 1.5")

-- multiplication of two gaussians
local a = gaussian.new(0, 1)
local b = gaussian.new(2, 3)
local ab = a * b
assert(approx(ab.mean, 0.5, 1e-3), "product of N(0,1)*N(2,3) mean should be ~0.5")

-- division of two gaussians
local d = a / b
assert(type(d.mean) == "number", "division result mean should be a number")
assert(type(d.variance) == "number", "division result variance should be a number")

-- addition and subtraction
local s = a + b
assert(approx(s.mean, 2), "sum mean should be 2")
assert(approx(s.variance, 4), "sum variance should be 4")

local diff = a - b
assert(approx(diff.mean, -2), "difference mean should be -2")
assert(approx(diff.variance, 4), "difference variance should be 4")

-- scale via multiply by number
local scaled = a * 3
assert(approx(scaled.mean, 0), "scaled mean should be 0")
assert(approx(scaled.variance, 9), "scaled variance should be 9")

-- scale via divide by number
local halved = g2 / 2
assert(approx(halved.mean, 5), "halved mean should be 5")
assert(approx(halved.variance, 1), "halved variance should be 1")

-- random produces correct count
local samples = g:random(100)
assert(#samples == 100, "random(100) should return 100 samples")

-- construction: very large variance
local gLarge = gaussian.new(0, 1e12)
assert(gLarge.variance == 1e12, "large variance should be preserved")
assert(approx(gLarge.standardDeviation, 1e6), "large variance stddev should be 1e6")

-- construction: very small variance
local gSmall = gaussian.new(0, 1e-10)
assert(gSmall.variance == 1e-10, "small variance should be preserved")
assert(approx(gSmall.standardDeviation, 1e-5), "small variance stddev should be 1e-5")

-- construction: negative mean
local gNeg = gaussian.new(-50, 4)
assert(gNeg.mean == -50, "negative mean should be preserved")
assert(gNeg.variance == 4, "variance with negative mean should be preserved")

-- pdf: known values at +/-1 for standard normal
assert(approx(g:pdf(1), 0.2419707, 1e-4), "pdf(1) should be ~0.2420")
assert(approx(g:pdf(-1), 0.2419707, 1e-4), "pdf(-1) should be ~0.2420")

-- pdf: symmetry
assert(approx(g:pdf(2), g:pdf(-2)), "pdf should be symmetric at +/-2")
assert(approx(g:pdf(0.7), g:pdf(-0.7)), "pdf should be symmetric at +/-0.7")

-- pdf: extreme values -> ~0
assert(g:pdf(10) < 1e-10, "pdf(10) should be near 0")
assert(g:pdf(-10) < 1e-10, "pdf(-10) should be near 0")

-- pdf: non-standard gaussian at its mean
local gNonStd = gaussian.new(5, 9) -- mean=5, variance=9, sd=3
assert(approx(gNonStd:pdf(5), 1 / (3 * math.sqrt(2 * math.pi)), 1e-6), "pdf at mean for N(5,9)")

-- cdf: known values at +/-1
assert(approx(g:cdf(1), 0.8413447, 1e-4), "cdf(1) should be ~0.8413")
assert(approx(g:cdf(-1), 0.1586553, 1e-4), "cdf(-1) should be ~0.1587")

-- cdf: known values at +/-2
assert(approx(g:cdf(2), 0.9772499, 1e-4), "cdf(2) should be ~0.9772")
assert(approx(g:cdf(-2), 0.0227501, 1e-4), "cdf(-2) should be ~0.0228")

-- cdf: known values at +/-3
assert(approx(g:cdf(3), 0.9986501, 1e-3), "cdf(3) should be ~0.9987")
assert(approx(g:cdf(-3), 0.0013499, 1e-3), "cdf(-3) should be ~0.0013")

-- cdf: symmetry property cdf(x) + cdf(-x) ~= 1
for _, x in ipairs({0.5, 1, 1.5, 2, 2.5, 3}) do
	assert(approx(g:cdf(x) + g:cdf(-x), 1, 1e-6), "cdf(x)+cdf(-x) should be 1 for x=" .. x)
end

-- ppf: known quantile 0.975 -> ~1.96
assert(approx(g:ppf(0.975), 1.96, 0.01), "ppf(0.975) should be ~1.96")

-- ppf: CDF -> PPF round-trips
for _, x in ipairs({-2.5, -1.5, -0.5, 0, 0.5, 1.5, 2.5}) do
	assert(approx(g:ppf(g:cdf(x)), x, 1e-3), "ppf(cdf(x)) should round-trip for x=" .. x)
end

-- ppf: PPF -> CDF round-trips
for _, p in ipairs({0.05, 0.25, 0.5, 0.75, 0.95}) do
	assert(approx(g:cdf(g:ppf(p)), p, 1e-3), "cdf(ppf(p)) should round-trip for p=" .. p)
end

-- scale: identity (x1)
local scaleId = g2:scale(1)
assert(approx(scaleId.mean, g2.mean), "scale(1) should preserve mean")
assert(approx(scaleId.variance, g2.variance), "scale(1) should preserve variance")

-- scale: negation (x-1)
local scaleNeg = g2:scale(-1)
assert(approx(scaleNeg.mean, -g2.mean), "scale(-1) should negate mean")
assert(approx(scaleNeg.variance, g2.variance), "scale(-1) should preserve variance")

-- scale: x0 should error (zero variance)
local okScale0 = pcall(function() g2:scale(0) end)
assert(not okScale0, "scale(0) should error due to zero variance")

-- operators: multiply by 1 is identity
local mulId = a * 1
assert(approx(mulId.mean, a.mean), "multiply by 1 should preserve mean")
assert(approx(mulId.variance, a.variance), "multiply by 1 should preserve variance")

-- operators: divide by 1 is identity
local divId = g2 / 1
assert(approx(divId.mean, g2.mean), "divide by 1 should preserve mean")
assert(approx(divId.variance, g2.variance), "divide by 1 should preserve variance")

-- operators: subtraction always adds variance
local sub1 = gaussian.new(10, 2) - gaussian.new(5, 3)
assert(approx(sub1.mean, 5), "subtraction mean should be 5")
assert(approx(sub1.variance, 5), "subtraction should add variances")

-- operators: addition associativity
local ga = gaussian.new(1, 1)
local gb = gaussian.new(2, 2)
local gc = gaussian.new(3, 3)
local assoc1 = (ga + gb) + gc
local assoc2 = ga + (gb + gc)
assert(approx(assoc1.mean, assoc2.mean), "addition should be associative (mean)")
assert(approx(assoc1.variance, assoc2.variance), "addition should be associative (variance)")

-- operators: add number should error
local okAddNum = pcall(function() return a + 5 end)
assert(not okAddNum, "adding a number to gaussian should error")

-- operators: subtract number should error
local okSubNum = pcall(function() return a - 5 end)
assert(not okSubNum, "subtracting a number from gaussian should error")

-- standardDeviation for non-trivial case
local gSD = gaussian.new(0, 16)
assert(approx(gSD.standardDeviation, 4), "stddev of variance=16 should be 4")

-- random: count=1
local singleSample = g:random(1)
assert(#singleSample == 1, "random(1) should return 1 sample")
assert(type(singleSample[1]) == "number", "random sample should be a number")

-- random: sample mean of 1000 draws within loose bounds
local manyDraws = gaussian.new(10, 4):random(1000)
local sum = 0
for _, v in ipairs(manyDraws) do sum = sum + v end
local sampleMean = sum / 1000
assert(approx(sampleMean, 10, 1), "sample mean of 1000 draws from N(10,4) should be near 10")

print("test_gaussian: PASSED")

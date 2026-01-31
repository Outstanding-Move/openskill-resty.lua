package.path = "../src/?.lua;" .. package.path

local constants = require("Constants")

-- defaults
assert(constants.z({}) == 3, "z default should be 3")
assert(constants.mu({}) == 25, "mu default should be 25")
assert(constants.sigma({}) == 25 / 3, "sigma default should be 25/3")
assert(constants.epsilon({}) == 0.0001, "epsilon default should be 0.0001")
assert(constants.beta({}) == (25 / 3) / 2, "beta default should be sigma/2")
assert(constants.betaSq({}) == ((25 / 3) / 2) ^ 2, "betaSq default should be beta^2")

-- overrides
assert(constants.z({z = 5}) == 5, "z override should be 5")
assert(constants.mu({mu = 30}) == 30, "mu override should be 30")
assert(constants.sigma({sigma = 10}) == 10, "sigma override should be 10")
assert(constants.epsilon({epsilon = 0.01}) == 0.01, "epsilon override should be 0.01")
assert(constants.beta({beta = 7}) == 7, "beta override should be 7")

-- sigma derived from custom mu/z
assert(constants.sigma({mu = 30, z = 5}) == 30 / 5, "sigma should derive from mu/z")

-- cascade: custom mu derives sigma, beta, betaSq
assert(constants.sigma({mu = 50}) == 50 / 3, "sigma should derive from custom mu")
assert(constants.beta({mu = 50}) == (50 / 3) / 2, "beta should cascade from custom mu")
assert(constants.betaSq({mu = 50}) == ((50 / 3) / 2) ^ 2, "betaSq should cascade from custom mu")

-- custom z affects sigma derivation
assert(constants.sigma({z = 5}) == 25 / 5, "sigma should derive from custom z")
assert(constants.beta({z = 5}) == (25 / 5) / 2, "beta should cascade from custom z")

-- custom sigma overrides derivation, cascades to beta
assert(constants.sigma({sigma = 10, mu = 50}) == 10, "explicit sigma should override mu-derived")
assert(constants.beta({sigma = 10}) == 10 / 2, "beta should cascade from custom sigma")
assert(constants.betaSq({sigma = 10}) == (10 / 2) ^ 2, "betaSq should cascade from custom sigma")

-- betaSq from custom beta
assert(constants.betaSq({beta = 7}) == 49, "betaSq from beta=7 should be 49")
assert(constants.betaSq({beta = 3}) == 9, "betaSq from beta=3 should be 9")

-- combined overrides: mu + z
assert(constants.sigma({mu = 100, z = 10}) == 10, "sigma from mu=100,z=10 should be 10")
assert(constants.beta({mu = 100, z = 10}) == 5, "beta from mu=100,z=10 should be 5")

-- all-explicit options bypass derivation
assert(constants.mu({mu = 42}) == 42, "explicit mu should be 42")
assert(constants.sigma({sigma = 7}) == 7, "explicit sigma should be 7")
assert(constants.beta({beta = 3}) == 3, "explicit beta should be 3")
assert(constants.betaSq({beta = 3}) == 9, "explicit beta=3 betaSq should be 9")
assert(constants.epsilon({epsilon = 0.5}) == 0.5, "explicit epsilon should be 0.5")
assert(constants.z({z = 2}) == 2, "explicit z should be 2")

print("test_constants: PASSED")

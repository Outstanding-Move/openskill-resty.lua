package.path = "../src/?.lua;../src/?/init.lua;" .. package.path

local openskill = require("OpenSkill")

local EPSILON = 1e-4

local function approx(a, b, eps)
	eps = eps or EPSILON
	return math.abs(a - b) < eps
end

-- Rating with defaults
local r = openskill.Rating()
assert(r.mu == 25, "default mu should be 25")
assert(approx(r.sigma, 25 / 3), "default sigma should be 25/3")

-- Rating with custom values
local r2 = openskill.Rating(30, 5)
assert(r2.mu == 30, "custom mu should be 30")
assert(r2.sigma == 5, "custom sigma should be 5")

-- Rating with only mu
local r3 = openskill.Rating(30)
assert(r3.mu == 30, "mu-only rating mu should be 30")
assert(type(r3.sigma) == "number", "mu-only rating sigma should be a number")

-- Ordinal
local ord = openskill.Ordinal(r)
assert(approx(ord, 25 - 3 * (25 / 3)), "ordinal should be mu - z*sigma")
assert(approx(ord, 0, 0.01), "default ordinal should be ~0")

-- Ordinal with custom z
local ord2 = openskill.Ordinal(r, {z = 2})
assert(approx(ord2, 25 - 2 * (25 / 3)), "ordinal with z=2 should be mu - 2*sigma")

-----------------------------------------------
-- Rate: two teams, no rank/score (default order)
-----------------------------------------------
local function freshTeams()
	return {
		{openskill.Rating(), openskill.Rating()},
		{openskill.Rating(), openskill.Rating()},
	}
end

local teams = freshTeams()
local result = openskill.Rate(teams)
assert(#result == 2, "Rate 2-team should return 2 teams")
assert(#result[1] == 2, "Rate team1 should have 2 players")
assert(#result[2] == 2, "Rate team2 should have 2 players")

-- winner mu should increase, loser mu should decrease
assert(result[1][1][1] > 25, "Rate winner p1 mu should increase")
assert(result[2][1][1] < 25, "Rate loser p1 mu should decrease")

-- sigma should decrease for all players (more certainty)
assert(result[1][1][2] < 25 / 3, "Rate winner sigma should decrease")
assert(result[2][1][2] < 25 / 3, "Rate loser sigma should decrease")

-- teams table should be mutated in place
assert(teams[1][1].mu == result[1][1][1], "Rate should mutate team1 p1 mu in place")
assert(teams[2][1].mu == result[2][1][1], "Rate should mutate team2 p1 mu in place")

-----------------------------------------------
-- Rate with explicit rank
-----------------------------------------------
local teams2 = freshTeams()
local result2 = openskill.Rate(teams2, {rank = {2, 1}})
assert(#result2 == 2, "Rate with rank should return 2 teams")
-- team 2 ranked 1st, team 1 ranked 2nd
assert(result2[2][1][1] > 25, "Rate rank winner mu should increase")
assert(result2[1][1][1] < 25, "Rate rank loser mu should decrease")

-----------------------------------------------
-- Rate with score
-----------------------------------------------
local teams3 = freshTeams()
local result3 = openskill.Rate(teams3, {score = {10, 20}})
assert(#result3 == 2, "Rate with score should return 2 teams")
-- higher score = better, so team2 (score=20) should improve
assert(result3[2][1][1] > 25, "Rate score=20 team mu should increase")
assert(result3[1][1][1] < 25, "Rate score=10 team mu should decrease")

-----------------------------------------------
-- Rate with ThurstoneMosteller model
-----------------------------------------------
local teamsTM = freshTeams()
local resultTM = openskill.Rate(teamsTM, {model = "ThurstoneMosteller"})
assert(#resultTM == 2, "Rate with TM should return 2 teams")
assert(resultTM[1][1][1] > 25, "Rate TM winner mu should increase")
assert(resultTM[2][1][1] < 25, "Rate TM loser mu should decrease")

-----------------------------------------------
-- Rate: three teams
-----------------------------------------------
local teams5 = {
	{openskill.Rating()},
	{openskill.Rating()},
	{openskill.Rating()},
}
local result5 = openskill.Rate(teams5)
assert(#result5 == 3, "Rate 3-team should return 3 teams")
-- 1st place gains most, 3rd place loses most
assert(result5[1][1][1] > result5[2][1][1], "Rate 3-team: 1st > 2nd")
assert(result5[2][1][1] > result5[3][1][1], "Rate 3-team: 2nd > 3rd")

-----------------------------------------------
-- WinProbability
-----------------------------------------------
local wp = openskill.WinProbability({
	{openskill.Rating()},
	{openskill.Rating()},
})
assert(#wp == 2, "WinProbability should return 2 entries")
-- equal teams should have ~equal win probability
assert(approx(wp[1], wp[2], 0.01), "equal teams should have equal win probability")
assert(approx(wp[1], 0.5, 0.01), "equal teams win probability should be ~0.5")

-- stronger team should have higher win probability
local wp2 = openskill.WinProbability({
	{openskill.Rating(40, 3)},
	{openskill.Rating(25, 8)},
})
assert(wp2[1] > wp2[2], "stronger team should have higher win probability")

-----------------------------------------------
-- DrawProbability
-----------------------------------------------
local dp = openskill.DrawProbability({
	{openskill.Rating()},
	{openskill.Rating()},
})
assert(type(dp) == "number", "DrawProbability should return a number")
assert(dp > 0 and dp < 1, "DrawProbability should be in (0, 1)")

-- edge: 0 teams
local dp0 = openskill.DrawProbability({})
assert(dp0 == nil, "DrawProbability with 0 teams should return nil")

-- edge: 1 team
local dp1 = openskill.DrawProbability({{openskill.Rating()}})
assert(dp1 == 1, "DrawProbability with 1 team should return 1")

-----------------------------------------------
-- Settings: DefaultModel
-----------------------------------------------
assert(openskill.Settings.DefaultModel == "PlackettLuce", "default model should be PlackettLuce")

-----------------------------------------------
-- Rating: with options table (mu override)
-----------------------------------------------
local rOpt = openskill.Rating(40, nil, {})
assert(rOpt.mu == 40, "Rating with options mu should be 40")
assert(type(rOpt.sigma) == "number", "Rating with options sigma should be a number")

-- Rating: with mu+z override in options
local rOptZ = openskill.Rating(50, nil, {z = 5})
assert(rOptZ.mu == 50, "Rating with z option mu should be 50")
assert(approx(rOptZ.sigma, 50 / 5), "Rating with z=5, mu=50 sigma should be 10")

-----------------------------------------------
-- Rate: score with ties (3 teams)
-----------------------------------------------
local teamsScoreTied = {
	{openskill.Rating()},
	{openskill.Rating()},
	{openskill.Rating()},
}
local resultScoreTied = openskill.Rate(teamsScoreTied, {score = {10, 10, 5}})
assert(#resultScoreTied == 3, "Rate score ties should return 3 teams")
-- teams 1 and 2 have same score (tied winners), team 3 loses
assert(approx(resultScoreTied[1][1][1], resultScoreTied[2][1][1], EPSILON),
	"tied score teams should have equal mu")
assert(resultScoreTied[1][1][1] > resultScoreTied[3][1][1],
	"tied winners mu should be > loser mu")

-----------------------------------------------
-- Rate: 4-team default ordering
-----------------------------------------------
local teams4def = {
	{openskill.Rating()}, {openskill.Rating()},
	{openskill.Rating()}, {openskill.Rating()},
}
local result4def = openskill.Rate(teams4def)
assert(#result4def == 4, "Rate 4-team should return 4 teams")
assert(result4def[1][1][1] > result4def[2][1][1], "Rate 4-team: 1st > 2nd")
assert(result4def[2][1][1] > result4def[3][1][1], "Rate 4-team: 2nd > 3rd")
assert(result4def[3][1][1] > result4def[4][1][1], "Rate 4-team: 3rd > 4th")

-----------------------------------------------
-- Rate: 5-team
-----------------------------------------------
local teams5b = {
	{openskill.Rating()}, {openskill.Rating()}, {openskill.Rating()},
	{openskill.Rating()}, {openskill.Rating()},
}
local result5b = openskill.Rate(teams5b)
assert(#result5b == 5, "Rate 5-team should return 5 teams")
for i = 1, 4 do
	assert(result5b[i][1][1] > result5b[i+1][1][1], "Rate 5-team: place " .. i .. " > place " .. (i+1))
end

-----------------------------------------------
-- Rate: all-tied (3 teams)
-----------------------------------------------
local teamsTied3 = {
	{openskill.Rating()}, {openskill.Rating()}, {openskill.Rating()},
}
local resultTied3 = openskill.Rate(teamsTied3, {rank = {1, 1, 1}})
assert(#resultTied3 == 3, "Rate all-tied should return 3 teams")
assert(approx(resultTied3[1][1][1], resultTied3[2][1][1], EPSILON), "tied teams 1,2 should have equal mu")
assert(approx(resultTied3[2][1][1], resultTied3[3][1][1], EPSILON), "tied teams 2,3 should have equal mu")

-----------------------------------------------
-- Rate: structure preservation (3v1)
-----------------------------------------------
local teams3v1 = {
	{openskill.Rating(), openskill.Rating(), openskill.Rating()},
	{openskill.Rating()},
}
local result3v1 = openskill.Rate(teams3v1)
assert(#result3v1 == 2, "Rate 3v1 should return 2 teams")
assert(#result3v1[1] == 3, "Rate 3v1 team1 should have 3 players")
assert(#result3v1[2] == 1, "Rate 3v1 team2 should have 1 player")

-----------------------------------------------
-- Rate: in-place mutation for 3-team
-----------------------------------------------
local teamsMut = {
	{openskill.Rating()}, {openskill.Rating()}, {openskill.Rating()},
}
local origRefs = {teamsMut[1][1], teamsMut[2][1], teamsMut[3][1]}
local resultMut = openskill.Rate(teamsMut)
for i = 1, 3 do
	assert(origRefs[i].mu == resultMut[i][1][1], "mutation: team " .. i .. " mu should match result")
	assert(origRefs[i].sigma == resultMut[i][1][2], "mutation: team " .. i .. " sigma should match result")
end

-----------------------------------------------
-- WinProbability: 3 equal teams (~1/3 each)
-----------------------------------------------
local wp3 = openskill.WinProbability({
	{openskill.Rating()}, {openskill.Rating()}, {openskill.Rating()},
})
assert(#wp3 == 3, "WinProbability 3 teams should return 3 entries")
for i = 1, 3 do
	assert(approx(wp3[i], 1/3, 0.05), "3 equal teams win prob should be ~1/3 for team " .. i)
end

-- WinProbability: probabilities sum ~= 1
local wpSum = 0
for _, v in ipairs(wp3) do wpSum = wpSum + v end
assert(approx(wpSum, 1, 0.05), "WinProbability sum should be ~1")

-- WinProbability: 4 teams with one strong
local wp4 = openskill.WinProbability({
	{openskill.Rating(50, 3)},
	{openskill.Rating()},
	{openskill.Rating()},
	{openskill.Rating()},
})
assert(#wp4 == 4, "WinProbability 4 teams should return 4 entries")
assert(wp4[1] > wp4[2], "strong team should have higher win prob than team 2")
assert(wp4[1] > wp4[3], "strong team should have higher win prob than team 3")
assert(wp4[1] > wp4[4], "strong team should have higher win prob than team 4")

-- WinProbability: 0 teams
local wp0 = openskill.WinProbability({})
assert(#wp0 == 0, "WinProbability with 0 teams should return empty")

-- WinProbability: single team wins by default
local wp1 = openskill.WinProbability({{openskill.Rating()}})
assert(#wp1 == 1, "WinProbability with 1 team should return 1 entry")
assert(wp1[1] == 1, "WinProbability with 1 team should be 1")

-----------------------------------------------
-- DrawProbability: equal > unequal
-----------------------------------------------
local dpEqual = openskill.DrawProbability({
	{openskill.Rating()}, {openskill.Rating()},
})
local dpUnequal = openskill.DrawProbability({
	{openskill.Rating(40, 3)}, {openskill.Rating(10, 3)},
})
assert(dpEqual > dpUnequal, "equal teams draw prob should be > unequal")

-- DrawProbability: 3 teams
local dp3 = openskill.DrawProbability({
	{openskill.Rating()}, {openskill.Rating()}, {openskill.Rating()},
})
assert(type(dp3) == "number", "DrawProbability 3 teams should return a number")
assert(dp3 > 0 and dp3 < 1, "DrawProbability 3 teams should be in (0, 1)")

-- DrawProbability: multi-player teams
local dpMulti = openskill.DrawProbability({
	{openskill.Rating(), openskill.Rating()},
	{openskill.Rating(), openskill.Rating()},
})
assert(type(dpMulti) == "number", "DrawProbability multi-player should return a number")
assert(dpMulti > 0 and dpMulti < 1, "DrawProbability multi-player should be in (0, 1)")

-----------------------------------------------
-- Model switching: PL vs TM produce different magnitudes
-----------------------------------------------
local teamsPL = {{openskill.Rating()}, {openskill.Rating()}}
local teamsTMswitch = {{openskill.Rating()}, {openskill.Rating()}}
local resPL = openskill.Rate(teamsPL)
local resTM = openskill.Rate(teamsTMswitch, {model = "ThurstoneMosteller"})
assert(resPL[1][1][1] > 25 and resTM[1][1][1] > 25, "both models should increase winner mu")
assert(resPL[1][1][1] ~= resTM[1][1][1], "PL and TM should produce different magnitudes")

-----------------------------------------------
-- Ordinal after Rate (winner > loser)
-----------------------------------------------
local teamsOrd = {{openskill.Rating()}, {openskill.Rating()}}
local resultOrd = openskill.Rate(teamsOrd)
local ordWinner = openskill.Ordinal({mu = resultOrd[1][1][1], sigma = resultOrd[1][1][2]})
local ordLoser = openskill.Ordinal({mu = resultOrd[2][1][1], sigma = resultOrd[2][1][2]})
assert(ordWinner > ordLoser, "winner ordinal should be > loser ordinal")

-----------------------------------------------
-- Convergence: 10 rounds of same matchup
-----------------------------------------------
local convA = openskill.Rating()
local convB = openskill.Rating()
local prevMuA = convA.mu
local prevMuB = convB.mu
local prevSigmaA = convA.sigma
local prevSigmaB = convB.sigma

for round = 1, 10 do
	local convTeams = {{convA}, {convB}}
	local convResult = openskill.Rate(convTeams)
	-- mu monotonically changes: winner increases, loser decreases
	assert(convA.mu >= prevMuA, "convergence round " .. round .. ": winner mu should not decrease")
	assert(convB.mu <= prevMuB, "convergence round " .. round .. ": loser mu should not increase")
	-- sigma monotonically decreases
	assert(convA.sigma <= prevSigmaA, "convergence round " .. round .. ": winner sigma should not increase")
	assert(convB.sigma <= prevSigmaB, "convergence round " .. round .. ": loser sigma should not increase")
	prevMuA = convA.mu
	prevMuB = convB.mu
	prevSigmaA = convA.sigma
	prevSigmaB = convB.sigma
end
-- after 10 rounds, winner should be significantly ahead
assert(convA.mu > convB.mu, "after 10 rounds winner mu should be > loser mu")
assert(convA.sigma < 25 / 3, "after 10 rounds winner sigma should have decreased")
assert(convB.sigma < 25 / 3, "after 10 rounds loser sigma should have decreased")

-----------------------------------------------
-- Error paths
-----------------------------------------------

-- Rate with empty teams
local emptyResult = openskill.Rate({})
assert(#emptyResult == 0, "Rate with empty teams should return empty")

-- Rate with invalid model name should error
local okBadModel = pcall(openskill.Rate,
	{{openskill.Rating()}, {openskill.Rating()}},
	{model = "NonExistent"})
assert(not okBadModel, "Rate with invalid model name should error")

print("test_openskill: PASSED")

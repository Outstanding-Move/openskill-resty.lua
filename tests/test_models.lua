package.path = "../src/?.lua;../src/?/init.lua;" .. package.path

local models = {
	PlackettLuce = require("Models.PlackettLuce"),
	ThurstoneMosteller = require("Models.ThurstoneMosteller"),
}
local util = require("Util")
local constants = require("Constants")

local EPSILON = 1e-4

local function approx(a, b, eps)
	eps = eps or EPSILON
	return math.abs(a - b) < eps
end

local function makeRating(mu, sigma)
	return {mu = mu or 25, sigma = sigma or 25 / 3}
end

-----------------------------------------------
-- Models table has both models
-----------------------------------------------
assert(type(models.PlackettLuce) == "function", "PlackettLuce should be a function")
assert(type(models.ThurstoneMosteller) == "function", "ThurstoneMosteller should be a function")

-----------------------------------------------
-- PlackettLuce: basic 2-team match
-----------------------------------------------
local game = {
	{makeRating(), makeRating()},
	{makeRating(), makeRating()},
}
local result = models.PlackettLuce(game, {})
assert(#result == 2, "PL 2-team should return 2 teams")
assert(#result[1] == 2, "PL team1 should have 2 players")
assert(#result[2] == 2, "PL team2 should have 2 players")

-- team 1 wins (default ordering), mu should increase
assert(result[1][1][1] > 25, "PL winner p1 mu should increase")
assert(result[1][2][1] > 25, "PL winner p2 mu should increase")
-- team 2 loses, mu should decrease
assert(result[2][1][1] < 25, "PL loser p1 mu should decrease")
assert(result[2][2][1] < 25, "PL loser p2 mu should decrease")

-- sigma should decrease for everyone
assert(result[1][1][2] < 25 / 3, "PL winner p1 sigma should decrease")
assert(result[2][1][2] < 25 / 3, "PL loser p1 sigma should decrease")

-----------------------------------------------
-- PlackettLuce: 3-team match ordering
-----------------------------------------------
local game3 = {
	{makeRating()},
	{makeRating()},
	{makeRating()},
}
local result3 = models.PlackettLuce(game3, {})
assert(#result3 == 3, "PL 3-team should return 3 teams")
assert(result3[1][1][1] > result3[2][1][1], "PL 1st place mu > 2nd place")
assert(result3[2][1][1] > result3[3][1][1], "PL 2nd place mu > 3rd place")

-----------------------------------------------
-- PlackettLuce: unequal teams
-----------------------------------------------
local gameUnequal = {
	{makeRating(40, 3)},
	{makeRating(25, 8)},
}
local resultU = models.PlackettLuce(gameUnequal, {})
-- strong team still gains (they won by default ordering)
assert(resultU[1][1][1] > 40, "PL strong winner should still gain mu")

-----------------------------------------------
-- ThurstoneMosteller: basic 2-team match
-----------------------------------------------
local gameTM = {
	{makeRating(), makeRating()},
	{makeRating(), makeRating()},
}
local resultTM = models.ThurstoneMosteller(gameTM, {})
assert(#resultTM == 2, "TM 2-team should return 2 teams")
assert(#resultTM[1] == 2, "TM team1 should have 2 players")

-- team 1 wins, mu up
assert(resultTM[1][1][1] > 25, "TM winner p1 mu should increase")
assert(resultTM[1][2][1] > 25, "TM winner p2 mu should increase")
-- team 2 loses, mu down
assert(resultTM[2][1][1] < 25, "TM loser p1 mu should decrease")
assert(resultTM[2][2][1] < 25, "TM loser p2 mu should decrease")

-- sigma decreases
assert(resultTM[1][1][2] < 25 / 3, "TM winner sigma should decrease")
assert(resultTM[2][1][2] < 25 / 3, "TM loser sigma should decrease")

-----------------------------------------------
-- ThurstoneMosteller: 3-team ordering
-----------------------------------------------
local gameTM3 = {
	{makeRating()},
	{makeRating()},
	{makeRating()},
}
local resultTM3 = models.ThurstoneMosteller(gameTM3, {})
assert(#resultTM3 == 3, "TM 3-team should return 3 teams")
assert(resultTM3[1][1][1] > resultTM3[2][1][1], "TM 1st place mu > 2nd place")
assert(resultTM3[2][1][1] > resultTM3[3][1][1], "TM 2nd place mu > 3rd place")

-----------------------------------------------
-- ThurstoneMosteller: tied ranks
-----------------------------------------------
local gameTied = {
	{makeRating()},
	{makeRating()},
}
local resultTied = models.ThurstoneMosteller(gameTied, {rank = {1, 1}})
assert(#resultTied == 2, "TM tied should return 2 teams")
-- tied match: both should stay near 25
assert(approx(resultTied[1][1][1], 25, 1), "TM tied team1 mu should be near 25")
assert(approx(resultTied[2][1][1], 25, 1), "TM tied team2 mu should be near 25")
-- and they should be equal to each other
assert(approx(resultTied[1][1][1], resultTied[2][1][1], EPSILON), "TM tied teams should have equal mu")

-----------------------------------------------
-- Both models produce different results
-----------------------------------------------
local gamePL = {{makeRating()}, {makeRating()}}
local gameTM2 = {{makeRating()}, {makeRating()}}
local rPL = models.PlackettLuce(gamePL, {})
local rTM = models.ThurstoneMosteller(gameTM2, {})
-- Both should have same direction but different magnitudes
assert(rPL[1][1][1] > 25 and rTM[1][1][1] > 25, "both models should increase winner mu")
assert(rPL[1][1][1] ~= rTM[1][1][1], "PL and TM should produce different magnitudes")

-----------------------------------------------
-- PlackettLuce: 4-team ordering
-----------------------------------------------
local game4PL = {
	{makeRating()}, {makeRating()}, {makeRating()}, {makeRating()},
}
local result4PL = models.PlackettLuce(game4PL, {})
assert(#result4PL == 4, "PL 4-team should return 4 teams")
assert(result4PL[1][1][1] > result4PL[2][1][1], "PL 4-team: 1st > 2nd")
assert(result4PL[2][1][1] > result4PL[3][1][1], "PL 4-team: 2nd > 3rd")
assert(result4PL[3][1][1] > result4PL[4][1][1], "PL 4-team: 3rd > 4th")

-----------------------------------------------
-- PlackettLuce: all-tied (3 teams)
-----------------------------------------------
local gamePLTied = {
	{makeRating()}, {makeRating()}, {makeRating()},
}
local resultPLTied = models.PlackettLuce(gamePLTied, {rank = {1, 1, 1}})
assert(#resultPLTied == 3, "PL all-tied should return 3 teams")
assert(approx(resultPLTied[1][1][1], resultPLTied[2][1][1], EPSILON), "PL tied teams 1,2 should have equal mu")
assert(approx(resultPLTied[2][1][1], resultPLTied[3][1][1], EPSILON), "PL tied teams 2,3 should have equal mu")

-----------------------------------------------
-- PlackettLuce: 2v2 multi-player
-----------------------------------------------
local game2v2PL = {
	{makeRating(), makeRating()},
	{makeRating(), makeRating()},
}
local result2v2PL = models.PlackettLuce(game2v2PL, {})
assert(#result2v2PL == 2, "PL 2v2 should return 2 teams")
assert(#result2v2PL[1] == 2, "PL 2v2 team1 should have 2 players")
assert(#result2v2PL[2] == 2, "PL 2v2 team2 should have 2 players")
assert(result2v2PL[1][1][1] > 25, "PL 2v2 winner p1 mu should increase")
assert(result2v2PL[1][2][1] > 25, "PL 2v2 winner p2 mu should increase")
assert(result2v2PL[2][1][1] < 25, "PL 2v2 loser p1 mu should decrease")
assert(result2v2PL[2][2][1] < 25, "PL 2v2 loser p2 mu should decrease")

-----------------------------------------------
-- PlackettLuce: 3v3
-----------------------------------------------
local game3v3PL = {
	{makeRating(), makeRating(), makeRating()},
	{makeRating(), makeRating(), makeRating()},
}
local result3v3PL = models.PlackettLuce(game3v3PL, {})
assert(#result3v3PL == 2, "PL 3v3 should return 2 teams")
assert(#result3v3PL[1] == 3, "PL 3v3 team1 should have 3 players")
assert(#result3v3PL[2] == 3, "PL 3v3 team2 should have 3 players")
for j = 1, 3 do
	assert(result3v3PL[1][j][1] > 25, "PL 3v3 winner p" .. j .. " mu should increase")
	assert(result3v3PL[2][j][1] < 25, "PL 3v3 loser p" .. j .. " mu should decrease")
end

-----------------------------------------------
-- PlackettLuce: extreme rating difference (50 vs 10)
-----------------------------------------------
local gameExtPL = {
	{makeRating(50, 3)},
	{makeRating(10, 3)},
}
local resultExtPL = models.PlackettLuce(gameExtPL, {})
assert(resultExtPL[1][1][1] > 50, "PL extreme winner mu should increase past 50")
assert(resultExtPL[2][1][1] < 10, "PL extreme loser mu should decrease past 10")

-----------------------------------------------
-- PlackettLuce: sigma always decreases
-----------------------------------------------
local gameSigPL = {
	{makeRating()}, {makeRating()}, {makeRating()},
}
local resultSigPL = models.PlackettLuce(gameSigPL, {})
for i = 1, 3 do
	assert(resultSigPL[i][1][2] < 25 / 3, "PL sigma should decrease for team " .. i)
end

-----------------------------------------------
-- PlackettLuce: custom epsilon
-----------------------------------------------
local gameEpsPL = {
	{makeRating()}, {makeRating()},
}
local resultEpsPL = models.PlackettLuce(gameEpsPL, {epsilon = 0.01})
assert(#resultEpsPL == 2, "PL custom epsilon should return 2 teams")
assert(resultEpsPL[1][1][1] > 25, "PL custom epsilon winner mu should increase")

-----------------------------------------------
-- PlackettLuce: custom beta
-----------------------------------------------
local gameBetaPL = {
	{makeRating()}, {makeRating()},
}
local resultBetaPL = models.PlackettLuce(gameBetaPL, {beta = 1})
assert(#resultBetaPL == 2, "PL custom beta should return 2 teams")
assert(resultBetaPL[1][1][1] > 25, "PL custom beta winner mu should increase")

-----------------------------------------------
-- ThurstoneMosteller: 4-team ordering
-----------------------------------------------
local game4TM = {
	{makeRating()}, {makeRating()}, {makeRating()}, {makeRating()},
}
local result4TM = models.ThurstoneMosteller(game4TM, {})
assert(#result4TM == 4, "TM 4-team should return 4 teams")
assert(result4TM[1][1][1] > result4TM[2][1][1], "TM 4-team: 1st > 2nd")
assert(result4TM[2][1][1] > result4TM[3][1][1], "TM 4-team: 2nd > 3rd")
assert(result4TM[3][1][1] > result4TM[4][1][1], "TM 4-team: 3rd > 4th")

-----------------------------------------------
-- ThurstoneMosteller: all-tied
-----------------------------------------------
local gameTMTied = {
	{makeRating()}, {makeRating()}, {makeRating()},
}
local resultTMTied = models.ThurstoneMosteller(gameTMTied, {rank = {1, 1, 1}})
assert(#resultTMTied == 3, "TM all-tied should return 3 teams")
assert(approx(resultTMTied[1][1][1], resultTMTied[2][1][1], EPSILON), "TM tied teams 1,2 should have equal mu")
assert(approx(resultTMTied[2][1][1], resultTMTied[3][1][1], EPSILON), "TM tied teams 2,3 should have equal mu")

-----------------------------------------------
-- ThurstoneMosteller: 2v2
-----------------------------------------------
local game2v2TM = {
	{makeRating(), makeRating()},
	{makeRating(), makeRating()},
}
local result2v2TM = models.ThurstoneMosteller(game2v2TM, {})
assert(#result2v2TM == 2, "TM 2v2 should return 2 teams")
assert(result2v2TM[1][1][1] > 25 and result2v2TM[1][2][1] > 25, "TM 2v2 winners mu should increase")
assert(result2v2TM[2][1][1] < 25 and result2v2TM[2][2][1] < 25, "TM 2v2 losers mu should decrease")

-----------------------------------------------
-- ThurstoneMosteller: extreme rating
-----------------------------------------------
local gameExtTM = {
	{makeRating(50, 3)},
	{makeRating(10, 3)},
}
local resultExtTM = models.ThurstoneMosteller(gameExtTM, {})
assert(resultExtTM[1][1][1] > 50, "TM extreme winner mu should increase past 50")
assert(resultExtTM[2][1][1] < 10, "TM extreme loser mu should decrease past 10")

-----------------------------------------------
-- ThurstoneMosteller: sigma always decreases
-----------------------------------------------
local gameSigTM = {
	{makeRating()}, {makeRating()}, {makeRating()},
}
local resultSigTM = models.ThurstoneMosteller(gameSigTM, {})
for i = 1, 3 do
	assert(resultSigTM[i][1][2] < 25 / 3, "TM sigma should decrease for team " .. i)
end

-----------------------------------------------
-- ThurstoneMosteller: custom beta/epsilon
-----------------------------------------------
local gameCustTM = {
	{makeRating()}, {makeRating()},
}
local resultCustTM = models.ThurstoneMosteller(gameCustTM, {beta = 2, epsilon = 0.01})
assert(#resultCustTM == 2, "TM custom beta/epsilon should return 2 teams")
assert(resultCustTM[1][1][1] > 25, "TM custom beta/epsilon winner mu should increase")

-----------------------------------------------
-- Cross-model: both agree on direction for 4 teams
-----------------------------------------------
local gameCross4PL = {{makeRating()}, {makeRating()}, {makeRating()}, {makeRating()}}
local gameCross4TM = {{makeRating()}, {makeRating()}, {makeRating()}, {makeRating()}}
local rCross4PL = models.PlackettLuce(gameCross4PL, {})
local rCross4TM = models.ThurstoneMosteller(gameCross4TM, {})
for i = 1, 3 do
	assert(rCross4PL[i][1][1] > rCross4PL[i+1][1][1], "PL cross-check: place " .. i .. " > place " .. (i+1))
	assert(rCross4TM[i][1][1] > rCross4TM[i+1][1][1], "TM cross-check: place " .. i .. " > place " .. (i+1))
end

-----------------------------------------------
-- Cross-model: both agree on tie result
-----------------------------------------------
local gameCrossTiePL = {{makeRating()}, {makeRating()}}
local gameCrossTieTM = {{makeRating()}, {makeRating()}}
local rCrossTiePL = models.PlackettLuce(gameCrossTiePL, {rank = {1, 1}})
local rCrossTieTM = models.ThurstoneMosteller(gameCrossTieTM, {rank = {1, 1}})
assert(approx(rCrossTiePL[1][1][1], rCrossTiePL[2][1][1], EPSILON), "PL tied teams should have equal mu")
assert(approx(rCrossTieTM[1][1][1], rCrossTieTM[2][1][1], EPSILON), "TM tied teams should have equal mu")

-----------------------------------------------
-- Error paths: empty teams
-----------------------------------------------
local resultEmptyPL = models.PlackettLuce({}, {})
assert(#resultEmptyPL == 0, "PL with empty teams should return empty")
local resultEmptyTM = models.ThurstoneMosteller({}, {})
assert(#resultEmptyTM == 0, "TM with empty teams should return empty")

-----------------------------------------------
-- Error paths: single team (no opponents)
-----------------------------------------------
local resultSinglePL = models.PlackettLuce({{makeRating()}}, {})
assert(#resultSinglePL == 1, "PL single team should return 1 team")
assert(approx(resultSinglePL[1][1][1], 25, EPSILON), "PL single team mu should be unchanged")
assert(approx(resultSinglePL[1][1][2], 25 / 3, EPSILON), "PL single team sigma should be unchanged")

local resultSingleTM = models.ThurstoneMosteller({{makeRating()}}, {})
assert(#resultSingleTM == 1, "TM single team should return 1 team")
assert(approx(resultSingleTM[1][1][1], 25, EPSILON), "TM single team mu should be unchanged")
assert(approx(resultSingleTM[1][1][2], 25 / 3, EPSILON), "TM single team sigma should be unchanged")

print("test_models: PASSED")

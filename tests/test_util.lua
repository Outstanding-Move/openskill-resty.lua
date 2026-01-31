package.path = "../src/?.lua;" .. package.path

local util = require("Util")

-- score
assert(util.score(1, 2) == 0, "score(1,2) should be 0 (loss)")
assert(util.score(2, 1) == 1, "score(2,1) should be 1 (win)")
assert(util.score(1, 1) == 0.5, "score(1,1) should be 0.5 (draw)")

-- rankings with no rank provided
local teams = {{}, {}, {}}
local r = util.rankings(teams)
assert(r[1] == 0, "default rank[1] should be 0")
assert(r[2] == 1, "default rank[2] should be 1")
assert(r[3] == 2, "default rank[3] should be 2")

-- rankings with ties
local r2 = util.rankings(teams, {1, 1, 2})
assert(r2[1] == 0, "tied rank[1] should be 0")
assert(r2[2] == 0, "tied rank[2] should be 0")
assert(r2[3] == 2, "tied rank[3] should be 2")

-- teamRating
local team1 = {{mu = 25, sigma = 8.333}}
local team2 = {{mu = 30, sigma = 7}}
local game = {team1, team2}
local tr = util.teamRating(game, {rank = {1, 2}})
assert(#tr == 2, "teamRating should return 2 entries")
assert(tr[1][1] == 25, "team1 mu should be 25")
assert(tr[2][1] == 30, "team2 mu should be 30")
assert(tr[1][4] == 0, "team1 rank should be 0")
assert(tr[2][4] == 1, "team2 rank should be 1")

-- teamRating with multi-player teams
local team3 = {{mu = 10, sigma = 5}, {mu = 20, sigma = 6}}
local tr2 = util.teamRating({team3}, {})
assert(tr2[1][1] == 30, "multi-player team mu should be summed (30)")
assert(math.abs(tr2[1][2] - (25 + 36)) < 0.001, "multi-player team sigma^2 should be summed (61)")

-- ladderPairs
local lp = util.ladderPairs({1, 2, 3})
assert(#lp == 3, "ladderPairs({1,2,3}) should have 3 entries")
assert(#lp[1] == 1, "first element should have 1 neighbor")
assert(lp[1][1] == 2, "first element neighbor should be 2")
assert(#lp[2] == 2, "middle element should have 2 neighbors")
assert(lp[2][1] == 1 and lp[2][2] == 3, "middle neighbors should be 1 and 3")
assert(#lp[3] == 1, "last element should have 1 neighbor")
assert(lp[3][1] == 2, "last element neighbor should be 2")

-- ladderPairs empty
local lp2 = util.ladderPairs({})
assert(#lp2 == 1 and #lp2[1] == 0, "empty ladderPairs should return {{}} with no neighbors")

-- c function
local options = {}
local teamRatings = {{25, 69.44, {}, 0}, {25, 69.44, {}, 1}}
local c = util.c(teamRatings, options)
assert(type(c) == "number", "c() should return a number")
assert(c > 0, "c() should be positive")

-- sumQ
local sq = util.sumQ(teamRatings, c)
assert(#sq == 2, "sumQ should return 2 entries")
assert(type(sq[1]) == "number", "sumQ entries should be numbers")

-- a function
local aResult = util.a(teamRatings)
assert(#aResult == 2, "a() should return 2 entries")
assert(aResult[1] == 1, "a[1] should be 1 (no ties)")
assert(aResult[2] == 1, "a[2] should be 1 (no ties)")

-- a with ties
local trTied = {{25, 69, {}, 0}, {25, 69, {}, 0}}
local aTied = util.a(trTied)
assert(aTied[1] == 2, "a[1] with ties should be 2")
assert(aTied[2] == 2, "a[2] with ties should be 2")

-- gamma default
local gam = util.gamma(10, 25, {})
assert(math.abs(gam - 5 / 10) < 0.001, "gamma default should be sqrt(sigmaSq)/c")

-- gamma custom
local gam2 = util.gamma(10, 25, {gamma = function() return 42 end})
assert(gam2 == 42, "custom gamma function should be used")

-- unwind
local t = {"a", "b", "c"}
local order = {3, 1, 2}
local sorted, tenet = util.unwind(t, order)
assert(sorted[1] == "b", "unwind sorted[1] should be 'b'")
assert(sorted[2] == "c", "unwind sorted[2] should be 'c'")
assert(sorted[3] == "a", "unwind sorted[3] should be 'a'")

-- unwind round-trip
local restored = util.unwind(sorted, tenet)
assert(restored[1] == "a", "round-trip restored[1] should be 'a'")
assert(restored[2] == "b", "round-trip restored[2] should be 'b'")
assert(restored[3] == "c", "round-trip restored[3] should be 'c'")

-- score: equal values
assert(util.score(0, 0) == 0.5, "score(0,0) should be 0.5")
assert(util.score(100, 100) == 0.5, "score(100,100) should be 0.5")

-- rankings: single team
local rSingle = util.rankings({{}})
assert(#rSingle == 1, "single team rankings should have 1 entry")
assert(rSingle[1] == 0, "single team rank should be 0")

-- rankings: all 4 tied
local r4tied = util.rankings({{}, {}, {}, {}}, {1, 1, 1, 1})
assert(r4tied[1] == 0, "4-tied rank[1] should be 0")
assert(r4tied[2] == 0, "4-tied rank[2] should be 0")
assert(r4tied[3] == 0, "4-tied rank[3] should be 0")
assert(r4tied[4] == 0, "4-tied rank[4] should be 0")

-- rankings: mixed ties (1,2,2,3)
local rMixed = util.rankings({{}, {}, {}, {}}, {1, 2, 2, 3})
assert(rMixed[1] == 0, "mixed rank[1] should be 0")
assert(rMixed[2] == 1, "mixed rank[2] should be 1")
assert(rMixed[3] == 1, "mixed rank[3] should be 1")
assert(rMixed[4] == 3, "mixed rank[4] should be 3")

-- rankings: 5-team default
local r5 = util.rankings({{}, {}, {}, {}, {}})
assert(r5[1] == 0, "5-team rank[1] should be 0")
assert(r5[2] == 1, "5-team rank[2] should be 1")
assert(r5[3] == 2, "5-team rank[3] should be 2")
assert(r5[4] == 3, "5-team rank[4] should be 3")
assert(r5[5] == 4, "5-team rank[5] should be 4")

-- teamRating: empty input
local trEmpty = util.teamRating({}, {})
assert(#trEmpty == 0, "empty teamRating should return empty")

-- teamRating: 3-player team sigma^2 summation
local team3p = {{mu = 10, sigma = 2}, {mu = 15, sigma = 3}, {mu = 20, sigma = 4}}
local tr3p = util.teamRating({team3p}, {})
assert(tr3p[1][1] == 45, "3-player team mu should sum to 45")
assert(math.abs(tr3p[1][2] - (4 + 9 + 16)) < 0.001, "3-player team sigma^2 should sum to 29")

-- ladderPairs: 1 element
local lp1 = util.ladderPairs({1})
assert(#lp1 == 1, "ladderPairs({1}) should have 1 entry")
assert(#lp1[1] == 0, "single element should have no neighbors")

-- ladderPairs: 2 elements
local lp2e = util.ladderPairs({10, 20})
assert(#lp2e == 2, "ladderPairs({10,20}) should have 2 entries")
assert(#lp2e[1] == 1, "first of 2 should have 1 neighbor")
assert(lp2e[1][1] == 20, "first neighbor should be 20")
assert(#lp2e[2] == 1, "second of 2 should have 1 neighbor (left only)")
assert(lp2e[2][1] == 10, "second neighbor should be 10")

-- ladderPairs: 4 elements (middle have 2 neighbors)
local lp4 = util.ladderPairs({1, 2, 3, 4})
assert(#lp4 == 4, "ladderPairs should have 4 entries")
assert(#lp4[1] == 1, "first of 4 should have 1 neighbor")
assert(lp4[1][1] == 2, "first neighbor should be 2")
assert(#lp4[2] == 2, "second of 4 should have 2 neighbors")
assert(lp4[2][1] == 1 and lp4[2][2] == 3, "second neighbors should be 1,3")
assert(#lp4[3] == 2, "third of 4 should have 2 neighbors")
assert(lp4[3][1] == 2 and lp4[3][2] == 4, "third neighbors should be 2,4")
assert(#lp4[4] == 1, "fourth of 4 should have 1 neighbor")
assert(lp4[4][1] == 3, "fourth neighbor should be 3")

-- c(): verify against manual formula
local cTeams = {{25, 69.44, {}, 0}, {30, 50, {}, 1}}
local cOptions = {}
local betaSqDef = ((25 / 3) / 2) ^ 2
local cExpected = math.sqrt(69.44 + betaSqDef + 50 + betaSqDef)
local cActual = util.c(cTeams, cOptions)
assert(math.abs(cActual - cExpected) < 0.01, "c() should match manual formula")

-- c(): with custom beta
local cCustom = util.c(cTeams, {beta = 10})
local cExpectedCustom = math.sqrt(69.44 + 100 + 50 + 100)
assert(math.abs(cCustom - cExpectedCustom) < 0.01, "c() with custom beta should match formula")

-- sumQ(): equal ranks (both sums equal)
local eqTeams = {{25, 69.44, {}, 0}, {25, 69.44, {}, 0}}
local cEq = util.c(eqTeams, {})
local sqEq = util.sumQ(eqTeams, cEq)
assert(math.abs(sqEq[1] - sqEq[2]) < 1e-6, "sumQ with equal ranks should be equal")

-- sumQ(): ordered ranks (first sum > second)
local ordTeams = {{25, 69.44, {}, 0}, {25, 69.44, {}, 1}}
local cOrd = util.c(ordTeams, {})
local sqOrd = util.sumQ(ordTeams, cOrd)
assert(sqOrd[1] > sqOrd[2], "sumQ[1] should be > sumQ[2] when rank[1] < rank[2]")

-- a(): 3 teams with 2 tied
local a3t = util.a({{25, 69, {}, 0}, {25, 69, {}, 0}, {25, 69, {}, 1}})
assert(a3t[1] == 2, "a[1] with 2 tied should be 2")
assert(a3t[2] == 2, "a[2] with 2 tied should be 2")
assert(a3t[3] == 1, "a[3] not tied should be 1")

-- a(): all 4 tied
local a4t = util.a({{25, 69, {}, 0}, {25, 69, {}, 0}, {25, 69, {}, 0}, {25, 69, {}, 0}})
assert(a4t[1] == 4, "a[1] all 4 tied should be 4")
assert(a4t[2] == 4, "a[2] all 4 tied should be 4")
assert(a4t[3] == 4, "a[3] all 4 tied should be 4")
assert(a4t[4] == 4, "a[4] all 4 tied should be 4")

-- unwind: single element
local uSingle, tSingle = util.unwind({"x"}, {1})
assert(uSingle[1] == "x", "single unwind should preserve element")
assert(tSingle[1] == 1, "single unwind tenet should be 1")

-- unwind: already sorted
local uSorted, tSorted = util.unwind({"a", "b", "c"}, {1, 2, 3})
assert(uSorted[1] == "a", "already-sorted[1] should be 'a'")
assert(uSorted[2] == "b", "already-sorted[2] should be 'b'")
assert(uSorted[3] == "c", "already-sorted[3] should be 'c'")

-- unwind: reverse order + round-trip
local uRev, tRev = util.unwind({"a", "b", "c"}, {3, 2, 1})
assert(uRev[1] == "c", "reverse unwind[1] should be 'c'")
assert(uRev[2] == "b", "reverse unwind[2] should be 'b'")
assert(uRev[3] == "a", "reverse unwind[3] should be 'a'")
local uRevBack = util.unwind(uRev, tRev)
assert(uRevBack[1] == "a", "reverse round-trip[1] should be 'a'")
assert(uRevBack[2] == "b", "reverse round-trip[2] should be 'b'")
assert(uRevBack[3] == "c", "reverse round-trip[3] should be 'c'")

-- unwind: duplicate order values (ties)
local uDup, tDup = util.unwind({"a", "b", "c"}, {1, 1, 2})
local found = {}
for _, v in ipairs(uDup) do found[v] = true end
assert(found["a"] and found["b"] and found["c"], "unwind with ties should preserve all elements")

-- gamma: additional formula verification
local gamVal = util.gamma(20, 100, {})
assert(math.abs(gamVal - math.sqrt(100) / 20) < 0.001, "gamma should be sqrt(sigmaSq)/c")
assert(math.abs(gamVal - 10 / 20) < 0.001, "gamma(20,100) should be 0.5")

print("test_util: PASSED")

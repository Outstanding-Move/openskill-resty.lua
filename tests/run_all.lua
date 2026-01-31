local tests = {
	"test_constants",
	"test_gaussian",
	"test_statistics",
	"test_util",
	"test_models",
	"test_openskill",
}

local failed = 0
for _, name in ipairs(tests) do
	local ok, err = pcall(dofile, name .. ".lua")
	if not ok then
		print(name .. ": FAILED")
		print("  " .. tostring(err))
		failed = failed + 1
	end
end

print("")
if failed == 0 then
	print("All " .. #tests .. " test files passed.")
else
	print(failed .. " of " .. #tests .. " test files failed.")
	os.exit(1)
end

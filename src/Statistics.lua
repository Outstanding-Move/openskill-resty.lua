local statistics = {}
local gaussian = require("Gaussian")

local normal = gaussian.new(0, 1)

function statistics.phiMajor(x)
	return normal:cdf(x)
end

function statistics.phiMajorInverse(x)
	return normal:ppf(x)
end

function statistics.phiMinor(x)
	return normal:pdf(x)
end

function statistics.v(x, t)
	local xt = x - t
	local denom = statistics.phiMajor(xt)
	return (denom < 2.2204460492503e-16 and -xt or statistics.phiMinor(xt) / denom)
end

function statistics.w(x, t)
	local xt = x - t
	local denom = statistics.phiMajor(xt)
	if denom < 2.2204460492503e-16 then
		return (x < 0 and 1 or 0)
	end
	return statistics.v(x, t) * (statistics.v(x, t) + xt)
end

function statistics.vt(x, t)
	local xx = math.abs(x)
	local b = statistics.phiMajor(t - xx) - statistics.phiMajor(-t - xx)
	if b < 1e-5 then
		if x < 0 then return -x - t end
		return -x + t
	end
	local a = statistics.phiMinor(-t - xx) - statistics.phiMinor(t - xx)
	return (x < 0 and -a or a) / b
end

function statistics.wt(x, t)
	local xx = math.abs(x)
	local b = statistics.phiMajor(t - xx) - statistics.phiMajor(-t - xx)
	return (b < 2.2204460492503e-16 and 1 or ((t - xx) * statistics.phiMinor(t - xx) +
		(t + xx) * statistics.phiMinor(-t - xx)) / b + statistics.vt(x, t) * statistics.vt(x, t))
end

return statistics
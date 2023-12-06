require "defense"

# Use memory store unless REDIS_URL is available in ENV (Redis is default)
Defense.store = Defense::MemoryStore.new if ENV["REDIS_URL"]?.nil?

# When safelist domains are provided (blank isn't allowed to safelist)
safelist = ENV.fetch("SAFELIST", "")
if safelist.presence
  domains = safelist.split(" ").map { |d| "(#{d})" }.join("|")
  regex_str = "^https?://#{domains}"
  safelist_regex = Regex.new(regex_str, Regex::CompileOptions::IGNORE_CASE)

  Defense.throttle("req/ip", limit: 0, period: 3) do |request|
    # Only throttle redirect path with a target (allow empty param for splash)
    next unless request.path == "/" && request.query_params["r"]?.presence

    # If there's a safelist match for the target don't throttle at all
    next unless (safelist_regex =~ request.query_params["r"]?).nil?

    # Not a match means we block that request - Use a single identifier
    # for all requests to avoid DoS by bloating our Defense cache store
    "block"
  end
else
  limit = ENV.fetch("THROTTLE_LIMIT", "5").to_i
  period = ENV.fetch("THROTTLE_PERIOD", "30").to_i

  Defense.throttle("req/ip", limit: limit, period: period) do |request|
    # Only throttle redirect path
    next unless request.path == "/"

    request.query_params["r"]?
  end
end

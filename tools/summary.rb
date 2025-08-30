#!/usr/bin/env ruby
require "csv"

if ARGV.length < 2
  warn "Usage: ruby summary.rb <input.csv> <output.csv>"
  exit 1
end

input, output = ARGV[0], ARGV[1]

def extract_seed_from_headers(headers)
  return nil unless headers
  # Try # ARGS seed=...
  args_cell = headers.find { |h| h && h.start_with?("# ARGS") }
  if args_cell
    m = args_cell.match(/seed\s*=\s*(\d+)/i)
    return m[1].to_i if m
  end
  # Fallback SEED:1234
  seed_cell = headers.find { |h| h && h.start_with?("SEED:") }
  if seed_cell
    return seed_cell.split(":", 2)[1].to_i rescue nil
  end
  nil
end

envstats = {}
seed = nil

CSV.open(input, headers: true, return_headers: false) do |csv|
  csv.each do |row|
    seed ||= extract_seed_from_headers(row.headers)

    env = row["Environment"]
    next if env.nil? || env.strip == ""

    bd_s  = row["B/D Ratio"]
    fit_s = row["Fitness"]

    bd  = (bd_s  && bd_s.strip  != "") ? bd_s.to_f  : Float::NAN
    fit = (fit_s && fit_s.strip != "") ? fit_s.to_f : Float::NAN

    stats = envstats[env] ||= {
      seed: seed,
      env: env.to_i,
      initial_bd: nil,
      final_bd: nil,
      min_bd: nil,
      max_bd: nil,
      avg_bd: 0.0,
      num_gens: 0,
      avg_fitness: 0.0
    }

    unless bd.nan?
      stats[:initial_bd] ||= bd
      stats[:final_bd] = bd
      stats[:min_bd] = bd if stats[:min_bd].nil? || bd < stats[:min_bd]
      stats[:max_bd] = bd if stats[:max_bd].nil? || bd > stats[:max_bd]
      stats[:avg_bd] += bd
    end

    stats[:avg_fitness] += fit unless fit.nan?
    stats[:num_gens] += 1
  end
end

envstats.each_value do |stats|
  if stats[:num_gens] > 0
    stats[:avg_bd]       = stats[:avg_bd] / stats[:num_gens]
    stats[:avg_fitness]  = stats[:avg_fitness] / stats[:num_gens]
  end
  stats[:diff_bd] = (stats[:initial_bd] && stats[:final_bd]) ? (stats[:final_bd] - stats[:initial_bd]) : "N/A"
end

envary = envstats.values.sort_by { |x| x[:env] }
envary.each_with_index do |x, idx|
  if idx > 0 && x[:initial_bd] && envary[idx-1][:final_bd]
    x[:bd_jump] = x[:initial_bd] - envary[idx - 1][:final_bd]
  else
    x[:bd_jump] = "N/A"
  end
end

if envary.empty?
  warn "No rows found in #{input}."
  exit 0
end

keylist = envary.first.keys.sort
CSV.open(output, "w") do |csv|
  csv << keylist
  envary.each { |x| csv << x.values_at(*keylist) }
end

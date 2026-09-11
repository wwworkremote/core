scrapers = [
  'cord', 'linkedin', 'indeed', 'dice', 'remoteok',
  'remotive', 'wwr', 'yc', 'glassdoor', 'builtin',
  'remoteio', 'flexjobs', 'bestjobs', 'echojobs', 'roberthalf'
]

scrapers.each do |slug|
  puts "Triggering #{slug}..."
  DataAcquisitionManager.run(slug, force: true)
end

puts "All scrapers triggered."

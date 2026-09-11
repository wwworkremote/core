boards = [
  'cord', 'linkedin', 'indeed', 'dice', 'remoteok',
  'remotive', 'wwr', 'yc', 'glassdoor', 'builtin',
  'remoteio', 'flexjobs', 'bestjobs', 'echojobs', 'roberthalf'
]

terms = [
  'Staff Ruby Engineer',
  'Principal Ruby Engineer',
  'Staff Rails Engineer',
  'Principal Rails Engineer',
  'Ruby on Rails Staff Engineer',
  'Senior Staff Ruby Engineer'
]

boards.each do |board|
  terms.each do |term|
    BoardQuery.find_or_create_by!(
      board_name: board,
      terms: [term],
      remote: true,
      priority: 1
    ) do |q|
      q.query_params = {
        remote: true,
        location: 'Remote',
        seniority: ['staff', 'principal', 'lead'],
        selector: 'a[href*="/job/"], a[href*="/jobs/"], .job-link, a[data-testid="job-title"]'
      }
    end
  end
end

puts "Seeded queries for #{boards.size} boards with #{terms.size} terms each."

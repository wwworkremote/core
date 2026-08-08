# frozen_string_literal: true

# Groups adjacent/lateral job titles into shared families (e.g. "Staff
# Engineer" and "Principal Engineer" both count as staff-plus IC) so
# ingestion and filtering can reason about a role in general, not one
# exact string. A lookup table, not an ML classifier -- aliases are
# literal phrases reviewed against real JobPosting titles.
module RoleFamily
  FAMILIES = {
    staff_plus_ic: [
      "Staff Engineer", "Staff Software Engineer", "Senior Staff Engineer",
      "Senior Staff Software Engineer", "Principal Engineer", "Distinguished Engineer",
      "Member of Technical Staff", "Fellow"
    ],
    engineering_management: [
      "Engineering Manager", "Senior Engineering Manager", "Director of Engineering",
      "VP Engineering", "VP of Engineering", "Vice President of Engineering",
      "Group Engineering Manager", "Head of Engineering"
    ],
    product_leadership: [
      "Director of Product", "Product Director", "VP Product", "VP of Product",
      "Head of Product", "Group Product Manager", "Principal Product Manager"
    ],
    design_leadership: [
      "Design Director", "Director of Design", "VP Design", "Head of Design", "Principal Designer"
    ],
    data_leadership: [
      "Staff Data Engineer", "Staff Data Scientist", "Principal Data Scientist",
      "Director of Data Science", "Head of Data"
    ]
  }.freeze

  def self.for(title)
    return nil if title.blank?

    FAMILIES.find { |_family, aliases| matches?(title, aliases) }&.first
  end

  def self.matches?(title, aliases)
    aliases.any? { |alias_text| title.downcase.include?(alias_text.downcase) }
  end
  private_class_method :matches?

  def self.aliases_for(family)
    FAMILIES.fetch(family, [])
  end
end

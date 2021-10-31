# frozen_string_literal: true

DOMAIN_WORDS = %w[
  API
  Adzuna
  AngelList
  AuthenticJobs
  BigDataJobs
  BuiltIn
  CareerBuilder
  CodeList
  Dice
  FindWork
  FullstackJobs
  GitHub
  GitLab
  GraphQLJobs
  HackerNews
  Indeed
  Jooble
  MeerkAds
  Monster
  Nexxt
  ReedCoUK
  Remote4Me
  RemoteIO
  RemoteInTech
  RemoteLeaf
  RemoteOK
  RemotePython
  Remotive
  RubyOnRemote
  StackOverflow
  TheMuse
  USAJobs
  Uncubed
  WeWorkRemotely
  WhoIsHiring
  WrkIs
  Wwwork
  WwworkRemote
  Wwwr
  ZipRecruiter
].freeze

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.uncountable(DOMAIN_WORDS.map(&:downcase).freeze)
  DOMAIN_WORDS.each { |word| inflect.acronym(word) }
end

# frozen_string_literal: true

DOMAIN_WORDS = %w[
  API
  OutlierJob
  OutlierJobs
  AngelList
  BigDataJobs
  BuiltIn
  CareerBuilder
  CodeList
  Dice
  FindWork
  FullstackJobs
  GitLab
  GitHub
  HackerNews
  Indeed
  MeerkAds
  Monster
  Nexxt
  Remote4Me
  RemoteIO
  RemoteInTech
  RemoteLeaf
  RemoteOK
  RemotePython
  Remotive
  RubyOnRemote
  StackOverflow
  USAJobs
  Uncubed
  WeWorkRemotely
  WhoIsHiring
  WrkIs
  ZipRecruiter
].freeze

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.uncountable(DOMAIN_WORDS.map(&:downcase).freeze)
  DOMAIN_WORDS.each { |word| inflect.acronym(word) }
end

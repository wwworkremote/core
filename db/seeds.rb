# frozen_string_literal: true

%w[
  Dice
  GitHub
  HackerNews
  Indeed
  Monster
  Nexxt
  RemoteOK
  RemotePython
  StackOverflow
  WeWorkRemotely
].each do |name|
  Origin.find_or_create_by(name: name)
end

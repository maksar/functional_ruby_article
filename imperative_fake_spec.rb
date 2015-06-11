require_relative 'spec_helper'
require_relative 'imperative'
require 'timecop'

describe(Imperative) do
  shared_examples 'birthday_sequence' do |today, result|
    before { allow(BirthdayRegistry).to receive(:birthday) { |_format, user| user.birthday } }
    %i(bob joe maria alice).permutation.each do |permutation|
      it "constructs birthday_sequence string from #{permutation.join(' ')} correctly" do
        Timecop.freeze(today) do
          expect(subject.birthday_sequence(users.values_at(*permutation))).to eq(result)
        end
      end
    end
  end

  include_context 'birthday sequence printing'
end

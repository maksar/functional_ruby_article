require_relative 'spec_helper'
require_relative 'functional'

describe(Functional) do
  let(:fake_registry) do
    Class.new do
      def self.birthday(_format, user)
        user.birthday
      end
    end
  end

  shared_examples 'birthday_sequence' do |today, result|
    %i(bob joe maria alice).permutation.each do |permutation|
      it "constructs birthday_sequence string from #{permutation.join(' ')} correctly" do
        expect(subject.birthday_sequence(users.values_at(*permutation), fake_registry, today)).to eq(result)
      end
    end
  end

  include_context 'birthday sequence printing'

  it 'works correctly without passing date' do
    expect(subject.birthday_sequence(users.values, fake_registry)).to be
  end
end

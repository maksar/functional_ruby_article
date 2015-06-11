shared_context 'birthday sequence printing' do
  let(:bob)   { double(:bob,   full_name: 'Bob',   birthday: Date.new(1985,  7, 16)) }
  let(:joe)   { double(:joe,   full_name: 'Joe',   birthday: Date.new(1985,  7, 16)) }
  let(:maria) { double(:maria, full_name: 'Maria', birthday: Date.new(1989,  1,  2)) }
  let(:alice) { double(:alice, full_name: 'Alice', birthday: Date.new(1989, 10, 25)) }

  let(:users) { { bob: bob, joe: joe, maria: maria, alice: alice } }

  context 'today is before all birthdays' do
    it_behaves_like 'birthday_sequence',
                    Date.new(1900, 1, 1), '[Bob, Joe] - 1985-07-16; [Maria] - 1989-01-02; [Alice] - 1989-10-25'
  end

  context 'today is on joe birthday' do
    it_behaves_like 'birthday_sequence',
                    Date.new(1985,  7, 16), '[Bob, Joe] - 1985-07-16; [Maria] - 1989-01-02; [Alice] - 1989-10-25'
  end

  context 'today is between joe and maria' do
    it_behaves_like 'birthday_sequence',
                    Date.new(1986, 1, 1), '[Bob, Joe] - 1985-07-16; [Maria] - 1989-01-02; [Alice] - 1989-10-25'
  end

  context 'today is between maria and alice' do
    it_behaves_like 'birthday_sequence',
                    Date.new(1989, 9, 5), '[Alice] - 1989-10-25; [Maria] - 1989-01-02; [Bob, Joe] - 1985-07-16'
  end

  context 'today is after all birthdays' do
    it_behaves_like 'birthday_sequence',
                    Date.new(2000, 1, 1), '[Alice] - 1989-10-25; [Maria] - 1989-01-02; [Bob, Joe] - 1985-07-16'
  end

  it 'works correctly without users' do
    expect(subject.birthday_sequence([])).to eq ''
  end
end

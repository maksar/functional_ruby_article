require_relative 'birthday_registry'

class Imperative
  def birthday_sequence(users)
    result = ''
    hash = {}
    users.each do |user|
      birthday = BirthdayRegistry.birthday(:date, user)
      hash[birthday] ||= []
      hash[birthday] << user
    end

    sorted = hash.sort_by { |birthday, _| (Date.today - birthday).abs }

    sorted.each do |birthday, celebrators|
      result << '['
      names = []
      celebrators.each { |user| names << user.full_name }
      names.sort!
      names[0..-2].each do |name|
        result << name
        result << ', '
      end
      result << names.last + "] - #{birthday}; "
    end
    result[0..-3]
  end
end

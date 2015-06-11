require 'active_support/all'
require_relative 'birthday_registry'

class Functional
  def birthday_sequence(users, registry = BirthdayRegistry, today = Date.today)
    users.group_by(&registry.method(:birthday).to_proc.curry[:date])
      .sort_by { |birthday, _| (today - birthday).abs }
      .map { |birthday, celebrators| "[#{celebrators.map(&:full_name).sort.join(', ')}] - #{birthday}" }
      .join('; ')
  end
end

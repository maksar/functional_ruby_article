class BirthdayRegistry
  def self.birthday(_format, user)
    # Simulating selay from external service.
    sleep(rand * 0.05)
    user.birthday
  end
end

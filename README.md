# Elements of functional programming in Ruby

Ruby is multi-paradigm programming language. It totally allows to write old-fashioned procedural code, but also provides many useful constructs and features from functional world.

Majority of developers comes to ruby from imperative world. They are used to making lots of local variables, changing their state and depending on implicit dependencies. Very quickly it becomes clear, that code can be much more expressive, using powerful idioms from functional languages. For sure, ruby isn't fully functional language: functions are not first class citizens, evaluation flow is not lazy, pattern matching support is very limited, etc. But still, it is possible to write code in functional way and have lots of benefits from that.

I'd like to start from practical example. Lets define a problem, try to solve it using both imperative and functional styles in ruby and see what happens. Its very hard to come up with good example for the article: it should be concise to be easily understandable and, at the same time, not look very artificial.

Problem definition:
Write a function, which accepts list of users with `full_name` property and returns a string with user's names and birthdays sorted by distance from current time.
Birthdays of users can be obtained from external system by using `birthday` method of `BirthdayRegistry` class.
If multiple people are lucky enough to be born same day - function should combine them together with a comma.

Example:
Having Bob and Joe, both with birthday on 16 July 1985, Maria celebrating birthday on 2 January 1989 and finally Alice who say the world on 25 October same year, function should return `"[Alice] - 1989-10-25; [Maria] - 1989-01-02; [Bob, Joe] - 1985-07-16"` string.

Imperative implementation:

```ruby
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
```

This example is, of course artificial, but code similar to this can be easily found in arbitrary ruby project with several junior developers. Its terrible in many senses, but is only for demonstration purposes of the article, please, be patient ;)

Lets re-write this function in functional style (actually, I wrote this one first, don't tell anyone), applying well-known ruby idioms.

```ruby
def birthday_sequence(users, registry = BirthdayRegistry, today = Date.today)
  users.group_by(&registry.method(:birthday).to_proc.curry[:date])
    .sort_by { |birthday, _| (today - birthday).abs }
    .map { |birthday, celebrators| "[#{celebrators.map(&:full_name).sort.join(', ')}] - #{birthday}" }
    .join('; ')
end
```

Out of the shelve, this looks much more concise than original variant. Even after refactoring of former (keeping imperative style) it will remain longer. This is very usual side-effect for writing programs functional style. It *forces* you to express _what_ in the code, instead of _how_.
Lets review interesting parts of second code example.


Give some attention to absence of variables in method, written in functional style. How much easier to extract formatting code out of it? You don't have to scan the method with your eyes, detecting all places where `result` variable is used.


Data transformation and filtering (`map`, `collect`, `inject`, `reduce`, `filter`, `detect`, `reject`, `zip`, etc.) - that is what makes ruby (as well as other functional languages) so expressive and concise. Every developers, new to ruby learns usefulness of these functions first. Indeed, its much more practical to just describe 'what' to do with data, instead of writing nasty 'for' loops. `users.map(&:full_name)` will iterate through users, extracting value of `full_name` property from each of them and return array of `full_name`s. `join` function will combine everything together, separating values by comma and a space.


`group_by` is a function, which groups an input array into *buckets* (arrays) by result of block evaluation on each value. So, given array of strings: `['foo', 'bar', 'buzz']`, `group_by { |string| string.length }` will return `{ 3 => ['foo', 'bar'], 4 => ['buzz'] }` hash. I know, it looks like a not completely fair substitution (original code does that 'by hands'), but `group_by` as well as `index_by` and similar concepts are very known in functional languages. Developer uses such data transformations as building blocks combining them with each other to achieve desired result instead of describing what computer should do on each step.


`.method`. In ruby, its a way to get a method object - 'pointer' to a method from an object. Here we are getting pointer to `birthday` method of the `registry`. & symbol converts method to a block, which can be then passed to any method expecting one. For example: `5.method(:modulo).call(2)` will give same result as `5.modulo(2)`. This is common way to pass method instead of a block.
But just getting a method isn't enough, `BirthdayRegistry.birthday` also accept format as first argument. Trick is to _curry_ that pointer to a method. In functional languages currying - is partially applying arguments to a function. Curry operation takes a proc of `N` arguments and returns a proc of one argument, which returns a proc of one argument, which returns... `N` times. You get the idea. In functional code example, we are currying `birthday` method, providing first argument to it (`call(:date)` notation is substituted with `[:date]` notation for shortness, ruby has many ways to call a function ;) ). Having that done, result can be used in `group_by` function as a block.


Sorting part looks essentially the same in both examples with one minor difference but very important difference. Imperative code just uses `Date.today` to get current date. This is a reference to a global, non-pure state! Result of `Date.today` is different each time (day) we call it. Having `Date.today` engraved into function body makes it very hard to test without *magical* `timecop` gem (which monkey-patches `Date` and can stop time for a while). Not even talking about the incorrect behavior of the birthday_sequence function itself - for each user `today` can be different and, therefore, time difference between birthday and `today` is different. Just imagine yourself debugging a defect, from QA team about 'off by hour' shift in the middle of user's birthdays string only twice a year.
Solution to that is also dependency injection. This is not a functional paradigm concept at all, but almost every functional program uses it. For a function to be pure, its not allowed to operate on external global state (otherwise, it will return non-deterministic results). So, instead of referring to global state, we injecting variable inside a function through its parameters. Doing so, eliminates the possibility for 'off by hour' defect to even appear (each time difference now calculated with same 'now' value).


Purity is, probably, most loved concept in functional languages is _pure_ functions. Function, which does not depend on any external state always returns same result, is very testable, reusable and easy to reason about. In majority of cases, it is also much easier to debug such function. Actually, no debugging needed, you just calling a function with some arguments and inspecting result. There is no way for external world (rest of the system) to influence on what pure function is going to return.
Signature `def birthday_sequence(users, registry = BirthdayRegistry, today = Date.today)` injects dependencies of a function from outside instead of referencing them from function body. Just looking at a function signature makes it clear for other developers, that it actually uses `today` inside, falling back to `Date.today` by default, if nothing was passed. With such signature, we can make function _pure_ (as soon as `BirthdayRegistry.birthday` is also pure).


Injection of `BirthdayRegistry` looks like not a big deal, but its hard to underestimate it. This little injection have huge implication to testing. Being good developer, you decided to write couple of unit tests to ensure, that `birthday_sequence` function works as expected. But before calling it and asserting result you need to setup an environment. You need to make sure, that `BirthdayRegistry.birthday` will actually return data for users you are testing function on. So, you have a choice of rather seeding an external storage (from which `BirthdayRegistry` takes its data) or mocking implementation of `birthday` method. Latter is easier, so you do `allow(BirthdayRegistry).to receive(:birthday).with(anything, user).and_return(...)`.
Now, look at your unit test. Developer who will read it later, will have no clue why you are setting up `BirthdayRegistry` mock before calling `birthday_sequence` function without looking on its implementation. Congrats, you now have semantic dependency. Every time you decide to work with `birthday_sequence` function, you'll have to keep in mind, that its actually calling `BirthdayRegistry` inside... Injection allows to pass stub implementation of `BirthdayRegistry` in unit test explicitly, without semantic dependency (if method accepts it in parameter, I bet its using it). key to shorten .


Comparing code from [imperative_fake_spec.rb](https://github.com/maksar/functional_ruby_article/blob/master/imperative_fake_spec.rb) and [imperative_real_spec.rb](https://github.com/maksar/functional_ruby_article/blob/master/imperative_real_spec.rb) tests, its even hard to see the difference, but its crucial for test feedback loop speed. Just stubbing out `BirthdayRegistry` dependency, we gaining speed, lots of speed. Since unit tests are not hitting database or any other external storage, they ca work lightning fast. Functional code test [functional_spec.rb](https://github.com/maksar/functional_ruby_article/blob/master/functional_spec.rb) encourages to pass fake implementation of external dependency leaving no chance to test slowness.
[![asciicast](https://asciinema.org/a/21318.png)](https://asciinema.org/a/21318)


Full sources of examples and unit tests can be found in [GitHub repo](https://github.com/maksar/functional_ruby_article)


There are many other topics, in which functional languages can affect way you write ruby code: [Monads](http://en.wikipedia.org/wiki/Monad_(functional_programming)), [higher order functions](http://en.wikipedia.org/wiki/Higher-order_function), [immutability](http://en.wikipedia.org/wiki/Immutable_object), etc. In this is article I tried to demonstrate basics, and inspire you to learn more towards making you code better.
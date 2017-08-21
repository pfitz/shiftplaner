alias Shiftplaner.{Day, Event, Person, Shift, Weekend}

event = Event.create_event(%{name: "Test Event", active: true})

d1 = Day.create_day(%{date: ~D[2018-08-20]})
d2 = Day.create_day(%{date: ~D[2018-08-21]})
d3 = Day.create_day(%{date: ~D[2018-08-22]})

week = Weekend.create_weekend_with_days([d1, d2, d3])

_event = Event.add_weekend_to_event(event, week)

d1_s1 = Shift.create_shift(%{worker_needed: 3, start_time: ~T[10:00:00], end_time: ~T[16:00:00]})
d1_s2 = Shift.create_shift(%{worker_needed: 3, start_time: ~T[16:00:00], end_time: ~T[22:00:00]})
d2_s1 = Shift.create_shift(%{worker_needed: 3, start_time: ~T[10:00:00], end_time: ~T[16:00:00]})
d2_s2 = Shift.create_shift(
  %{worker_needed: 2, griller_needed: 0, start_time: ~T[12:00:00], end_time: ~T[18:00:00]}
)
d2_s3 = Shift.create_shift(%{worker_needed: 3, start_time: ~T[16:00:00], end_time: ~T[22:00:00]})
d3_s1 = Shift.create_shift(%{worker_needed: 3, start_time: ~T[10:00:00], end_time: ~T[16:00:00]})
d3_s2 = Shift.create_shift(
  %{worker_needed: 2, griller_needed: 0, start_time: ~T[12:00:00], end_time: ~T[18:00:00]}
)
d3_s3 = Shift.create_shift(%{worker_needed: 3, start_time: ~T[16:00:00], end_time: ~T[22:00:00]})

Day.add_shift(d1, [d1_s1, d1_s2])
Day.add_shift(d2, [d2_s1, d2_s2, d2_s3])
Day.add_shift(d3, [d3_s1, d3_s2, d3_s3])

p1 = Person.create_person(
  %{
    first_name: "Friedrich",
    sure_name: "Pfitzmann",
    email: "test@test.de",
    phone: "06541987123",
    is_griller: true
  }
)
p2 = Person.create_person(
  %{
    first_name: "Gernot",
    sure_name: "Weyrich",
    email: "test@test.de",
    phone: "06541123987",
    is_griller: true
  }
)
p3 = Person.create_person(
  %{
    first_name: "Mike",
    sure_name: "Weirich",
    email: "test@test.de",
    phone: "06541345876",
    is_griller: false
  }
)
p4 = Person.create_person(
  %{
    first_name: "Frank",
    sure_name: "Lebenstedt",
    email: "test@test.de",
    phone: "06541987123",
    is_griller: false
  }
)

Person.add_person_as_available_for_shift(p1, [d1_s2, d2_s1, d2_s3, d3_s1])
Person.add_person_as_available_for_shift(p2, [d1_s1, d2_s1, d2_s2, d3_s2])
Person.add_person_as_available_for_shift(p3, [d1_s2, d2_s2, d2_s3, d3_s3])
Person.add_person_as_available_for_shift(p4, [d1_s1, d2_s3, d3_s1, d3_s2, d3_s3])
